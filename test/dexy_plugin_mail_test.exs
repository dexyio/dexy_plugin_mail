defmodule DexyPluginMailTest do
  use ExUnit.Case
  import Bamboo.Email
  doctest DexyPluginMail

  alias DexyPluginMail.SMTPClient

  defmodule BambooTest do
    def test_mail do
      new_email \
        to: "winfavor@gmail.com",
        from: "noreply@dexy.io",
        subject: "Confirm your subscription",
        html_body: """ 
          <h2>Please Confirm Subscription</h2>
          <p><a href="http://dexy.io:8082"><span>Yes, subscribe me to dexy.io</span></a></p>
          <div>
          <p>If you received this email by mistake, simply delete it. You won't be subscribed if you don't click the confirmation link above.</p>
          </div>
        """
    end 

    def send_mail do
      opts = %{
        "to" => "winfavor@gmail.com",
        "from" => "noreply@dexy.io",
        "subject" => "Confirm your subscription 2",
        "html" => """ 
          <h2>Please Confirm Subscription 2</h2>
          <p><a href="http://dexy.io:8082"><span>Yes, subscribe me to dexy.io</span></a></p>
          <div>
          <p>If you received this email by mistake, simply delete it. You won't be subscribed if you don't click the confirmation link above.</p>
          </div>
        """
      }
      DexyPluginMail.send %{args: [], opts: opts}
    end
  end

  test "bamboo - mail send" do
    #assert %Bamboo.Email{} = BambooTest.test_mail |> DexyPluginMail.Adapters.Bamboo.deliver_now
    #assert {_, "ok"} = BambooTest.send_mail 
  end 

  test "smtp - mail smaple" do
    :gen_smtp_client.send_blocking({
      "ykmaeng@finotek.co.kr",
      ["winfavor@gmail.com", "ykmaeng@gmail.com"],
      """
      Subject: 테스트 메일입니다.
      From: 테스터 <ykmaeng@finotek.co.kr>
      To: Developers 
      Cc: Kook <ykmaeng@gmail.com>
      Content-Type: multipart/alternative; boundary=aaa

      --aaa
      Content-Type: text/plain; charset=utf-8

      {"name":"Foo bar","age":10} 
      --aaa
      Content-Type: text/html; charset=utf-8

      <html>{"name":"Foo bar","age":10}</html>
      --aaa--
      """
      }, [
        relay: "smtp.mail.com",
        username: "foo",
        password: "foo",
        port: 587,
      ])
  end

  test "smtp - to_struct" do
    props = %{
      "from" => "foo@mail.com",
      "to" => [{"테스터", "foo@mail.com"}, "bar@mail.com", "Baz <baz@mail.com>"],
      "subject" => "This is a title.",
      "body" => "This is a mail body",
      "relay" => "smtp.mail.com",
      "port" => 999,
      "username" => "foo",
      "password" => "bar",
    } |> SMTPClient.to_struct

    assert %SMTPClient{
      from_addr: "foo@mail.com",
      to_addrs: ["baz@mail.com", "bar@mail.com", "foo@mail.com"],
      from: "foo@mail.com",
      to: "테스터 <foo@mail.com>, bar@mail.com, Baz <baz@mail.com>",
      to_alias: nil, cc: nil,
      subject: "This is a title.",
      content_type: nil, boundary: nil,
      body: "This is a mail body",
      relay: "smtp.mail.com", port: 999,
      username: "foo", password: "bar",
    } == props
  end

  test "smtp - build mail" do
    props = %{
      "from" => "foo@mail.co.kr",
      "to" => "bar@mail.com",
      "cc" => "baz@mail.com",
      "subject" => "테스트 메일",
      "body" => "Welcome, 테스트 메일입니다!",
      "relay" => "smtp.mail.com",
      "port" => 999,
      "username" => "foo",
      "password" => "bar",
    }
    props |> SMTPClient.to_struct |> SMTPClient.build_mail |> IO.inspect; IO.puts ""
    props |> Map.put("body", ["Welcome, 테스트 메일!", "<html>Welcome, 테스트 메일!</html>"])
          |> SMTPClient.to_struct |> SMTPClient.build_mail |> IO.inspect
  end

  test "smtp - send" do
    opts = %{
      "from" => "Kook <ykmaeng@finotek.co.kr>",
      "to" => "winfavor@gmail.com, 마눌하 <unsun153@gmail.com>",
      "cc" => "Bar <ykmaeng@gmail.com>",
      "subject" => "테스트 메일",
      "content-type" => "text/html; charset=utf-8",
      "body" => "<h2>Hello, 테스트 메일3 입니다!</h2>",
      "relay" => "smtp.worksmobile.com",
      "port" => 587,
      "username" => "ykmaeng@finotek.co.kr",
      "password" => "Ekdnlt09!",
    } 
    {_state, res} = DexyPluginMail.smtp_send %{args: [], opts: opts, mappy: Map.new}
    IO.inspect res
  end

  import DexyPluginMail.SMTPClient, only: [addr_list: 1]
  test "get just addr" do
    assert addr_list("Foo <foo@mail.com>") == ["foo@mail.com"]
    assert addr_list("<foo@mail.com>") == ["foo@mail.com"]
    assert addr_list("foo@mail.com") == ["foo@mail.com"]
    assert addr_list({"Foo", "foo@mail.com"}) == ["foo@mail.com"]

    assert addr_list(["Foo <foo@mail.com>", "bar@mail.com"])
      == ["bar@mail.com", "foo@mail.com"]
    assert addr_list(["<foo@mail.com>", "Bar <bar@mail.com>"])
      == ["bar@mail.com", "foo@mail.com"]
    assert addr_list(["foo@mail.com", "bar@mail.com"])
      == ["bar@mail.com", "foo@mail.com"]
    assert addr_list([{"Foo", "foo@mail.com"}, "bar@mail.com"])
      == ["bar@mail.com", "foo@mail.com"]
    assert addr_list([{"Foo", "foo@mail.com"}, "bar@mail.com", "Baz <baz@mail.com>", "invalid@mail"])
      == ["baz@mail.com", "bar@mail.com", "foo@mail.com"]
    assert addr_list("Foo <foo.bar@complex-type.domain.name>")
      == ["foo.bar@complex-type.domain.name"]
  end

end
