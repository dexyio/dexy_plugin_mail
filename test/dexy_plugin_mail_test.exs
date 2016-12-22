defmodule DexyPluginMailTest do
  use ExUnit.Case
  import Bamboo.Email
  doctest DexyPluginMail

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

  test "bamboo" do
    #assert %Bamboo.Email{} = BambooTest.test_mail |> DexyPluginMail.Adapters.Bamboo.deliver_now
    #assert {_, "ok"} = BambooTest.send_mail 
  end 

end
