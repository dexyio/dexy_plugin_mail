defmodule DexyPluginMail.Adapters.Bamboo do

  use Bamboo.Mailer, otp_app: :dexy_plugin_mail
  import Bamboo.Email

  @behaviour DexyPluginMail.Adapter

  def send args do
    case args |> new_email |> deliver_now do
      %Bamboo.Email{} -> :ok
      error = {:error, _reason} -> error
    end
  end

end
