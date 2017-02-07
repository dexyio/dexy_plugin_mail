defmodule DexyPluginMail do

  @adapter Application.get_env(:dexy_plugin_mail, __MODULE__)[:adapter]
    || __MODULE__.Adapters.Bamboo

  defmodule Adapter do
    @callback send(Keywords.t) :: :ok | {:error, term}
  end

  use DexyLib, as: Lib
  require Logger

  deferror Error.SMTPSendFailed

  def send state = %{args: [], opts: opts} do do_send state, opts end 

  defp do_send(state, opts) do
    res = case Enum.map(opts, &do_send &1) |> @adapter.send() do
      :ok -> "ok"
      {:error, reason} -> (error = inspect reason) |> Logger.warn; error
    end
    {state, res}
  end 

  defp do_send({"from", val}) when is_tuple(val) or is_bitstring(val),
       do: {:from, val}

  defp do_send({"to", val}) when is_list(val) or is_bitstring(val),
       do: {:to, val}

  defp do_send({"cc", val}) when is_list(val) or is_bitstring(val),
       do: {:cc, val}

  defp do_send({"bcc", val}) when is_list(val) or is_bitstring(val),
       do: {:bcc, val}

  defp do_send({"subject", val}) when is_list(val) or is_bitstring(val),
       do: {:subject, val}

  defp do_send({"text", val}) when is_list(val) or is_bitstring(val),
       do: {:text_body, val}

  defp do_send({"html", val}) when is_list(val) or is_bitstring(val),
       do: {:html_body, val}

  def smtp_send state = %{args: [], opts: opts} do do_smtp_send state, data!(state), opts end 
  def smtp_send state = %{args: [body], opts: opts} do do_smtp_send state, body, opts end 

  defp do_smtp_send state, body, opts do
    case opts["body"] do
      nil -> Map.put(opts, "body", body)
      _ -> opts
    end
    |> __MODULE__.SMTPClient.send
    |> case do
      :ok -> {state, "ok"}
      {:error, reason} -> raise Error.SMTPSendFailed, state: state, reason: reason
    end
  end

  defp data! %{mappy: map} do
    Lib.Mappy.val map, "data"
  end

end
