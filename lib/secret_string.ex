use Croma

defmodule Blick.PrintableString do
  @type t :: String.t

  def valid?(str) when is_binary(str), do: String.printable?(str)
  def valid?(_), do: false
end

defmodule Blick.SecretString do
  @moduledoc """
  Struct module representing secret information in `Blick.PrintableString`,
  which will always be encrypted on JSON serialization, and decrypted on deserialization.

  ## How it works

  `Poison.Encoder` protocol can be implemented for struct module,
  (as long as it is prefixed by "YourGear.", otherwise solomon_static_analysis will bark on),
  which dictates how that struct value will be serialized on `Poison.encode/1`.

  `#{inspect(__MODULE__)}` utilizes that feature, ensuring secret information will not leak out of ErlangVM
  by encrypting `String` value on serialization (using AES cryptosystem).
  """

  use Croma.Struct, fields: [
    value: Blick.PrintableString,
  ]
  alias Croma.Result, as: R

  defun new(any :: any) :: Croma.Result.t(t) do
    str when is_binary(str) ->
      str |> Blick.decrypt_base64() |> R.map(&%__MODULE__{value: &1})
    otherwise ->
      super(otherwise)
  end
end

defimpl Poison.Encoder, for: Blick.SecretString do
  def encode(%Blick.SecretString{value: raw_value}, _opts) do
    Blick.encrypt_base64!(raw_value)
  end
end
