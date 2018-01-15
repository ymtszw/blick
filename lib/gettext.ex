use Croma

defmodule Blick.Gettext do
  use SolomonLib.Gettext, otp_app: :blick

  defun put_locale(locale :: v[String.t]) :: nil do
    Gettext.put_locale(__MODULE__, locale)
  end
end
