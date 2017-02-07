defmodule DexyPluginMail.SMTPClient do

  defstruct from_addr: nil,
            to_addrs: nil,
            from: nil,
            to: nil,
            to_alias: nil,
            cc: nil,
            subject: nil,
            content_type: nil,
            boundary: nil,
            body: nil,
            full_mail: nil,

            relay: nil,
            port: nil,
            username: nil,
            password: nil

  @type t :: %__MODULE__{
    from_addr: bitstring,
    to_addrs: list,
    from: bitstring,
    to: bitstring,
    to_alias: bitstring,
    cc: bitstring,
    subject: bitstring,
    content_type: bitstring,
    boundary: bitstring,
    body: bitstring,
    full_mail: bitstring,
    # Relay setting
    relay: bitstring,
    port: pos_integer,
    username: bitstring,
    password: bitstring
  }

  use DexyLib, as: Lib

  def send props do
    props |> to_struct |> build_mail |> send_mail
  end

  def to_struct(props) when is_map(props) do
    to_list = (props["to"] || throw :smtp_to_required) |> addr_list
    cc_list = (props["cc"] || []) |> addr_list
    to_addrs = to_list ++ cc_list 
    %__MODULE__{
      from_addr: (props["from"] || throw :smtp_from_required) |> addr_list |> List.first,
      to_addrs: to_addrs,
      from: props["from"] |> fix_from,
      to: props["to_alias"] || (props["to"] |> fix_to),
      cc: props["cc"],
      subject: (props["subject"] || throw :smtp_subject_required),
      content_type: props["content-type"] || props["content_type"],
      body: props["body"],

      relay: (props["relay"] || throw :smtp_relay_required),
      port: (props["port"] || throw :smtp_port_required),
      username: (props["username"] || throw :smtp_username_required),
      password: (props["password"] || throw :smtp_password_required),
    }
  end

  def build_mail smtp = %__MODULE__{} do
    smtp = set_content_type(smtp)
    full_mail =
      "From: #{smtp.from}\r\nTo: #{smtp.to}\r\nSubject: #{smtp.subject}\r\n"
      <> (smtp.cc && "Cc: #{smtp.cc}\r\n" || "")
      <> "Content-Type: #{smtp.content_type}\r\n\r\n"
      <> mail_body(smtp)
      <> "\r\n"
    %{smtp | full_mail: full_mail}
  end

  defp send_mail smtp do
    :gen_smtp_client.send_blocking({
      smtp.from_addr,
      smtp.to_addrs,
      smtp.full_mail
    }, [
      relay: smtp.relay,
      username: smtp.username,
      password: smtp.password,
      port: smtp.port
    ])
    |> case do
      "ok" <> _ -> :ok
      {:error, reason} -> {:error, reason}
      {:error, reason, detail} -> {:error, [reason, inspect detail]}
    end
  end

  defp mail_body(smtp = %__MODULE__{body: body}) when is_list(body) do
    boundary = smtp.boundary
    body = Enum.map(body, fn
      {type, content} ->
        "--#{boundary}\r\nContentType: #{type}\r\n\r\n#{body_to_string content}\r\n"
      content ->
        "--#{boundary}\r\nContentType: text/plain; charset=utf-8\r\n\r\n"
        <> "#{body_to_string content}\r\n"
    end) |> Enum.join
    body <> "--#{boundary}--"
  end

  defp mail_body(%__MODULE__{body: body}) do body_to_string body end

  defp body_to_string(body) when is_bitstring(body), do: body
  defp body_to_string(nil), do: ""
  defp body_to_string(body), do: inspect body

  defp set_content_type(smtp = %__MODULE__{body: body}) when is_list(body) do
    boundary = Lib.unique
    content_type = case smtp.content_type do
      nil -> "multipart/mixed; boundary=#{boundary}"
      type -> type <> "; boundary=#{boundary}"
    end
    %{smtp | content_type: content_type, boundary: boundary}
  end

  defp set_content_type(smtp = %__MODULE__{content_type: type}) do
    type && smtp || %{smtp | content_type: "text/plain; charset=utf-8"}
  end

  defp fix_from(addr) when is_bitstring(addr) do addr end
  defp fix_from {name, addr} do "#{name} <#{addr}>" end
  
  defp fix_to(addr) when is_bitstring(addr) do addr end
  defp fix_to {name, addr} do "#{name} <#{addr}>" end

  defp fix_to(to_list) when is_list(to_list) do
    to_list |> Enum.map(&fix_to &1) |>  Enum.join(", ")
  end

  def addr_list {_name, addr} do do_addr_list [addr], [] end
  def addr_list(str) when is_bitstring(str) do do_addr_list [str], [] end
  def addr_list(list) when is_list(list) do do_addr_list list, [] end

  defp do_addr_list [], acc do List.flatten acc end
  defp do_addr_list [{_name, addr} | rest], acc do do_addr_list [addr | rest], acc end

  defp do_addr_list([addr | rest], acc) when is_bitstring(addr)  do
    res = Regex.scan ~R/[\w+\.\-]+@[\w+\-]+(?:\.[a-z]+)+/u, addr
    do_addr_list rest, [res | acc]
  end

  defp do_addr_list [_ | rest], acc do do_addr_list rest, acc end

end
