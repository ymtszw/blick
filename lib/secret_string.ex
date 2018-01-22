use Croma

defmodule Blick.PrintableString do
  @type t :: String.t

  def valid?(str) when is_binary(str), do: String.printable?(str)
  def valid?(_), do: false
end

defmodule Blick.SecretString do
  @moduledoc false

  # Struct module representing secret information in `PrintableString`,
  # which will always be encrypted on JSON serialization, and decrypted on deserialization.
  #
  # ## How it works
  #
  # `Poison.Encoder` protocol can be implemented for struct module,
  # (as long as it is prefixed by "YourGear.", otherwise solomon_static_analysis will bark on),
  # which dictates how that struct value will be serialized on `Poison.encode/1`.
  #
  # `SecretString` utilizes that feature, ensuring secret information will not leak out of solomon ErlangVM
  # by always encrypting `PrintableString` value on serialization (using AES cryptosystem).
  #
  # It also implement `Inspect` protocol so that inspecting the struct will not expose its value.
  # This also applies to echo-back on iex.
  # Though directly extracting value of `:value` field WILL result in exposure of it.
  # This should be considered "the last resort" for debugging secret information
  # by those who know implementation details.

  use Croma.Struct, fields: [
    value: Blick.PrintableString,
  ]

  # Overloading new/1
  def new(str) when is_binary(str) do
    str |> Blick.decrypt_base64() |> Croma.Result.map(&%__MODULE__{value: &1})
  end
  def new(otherwise) do
    super(otherwise)
  end
end

defimpl Poison.Encoder, for: Blick.SecretString do
  def encode(%Blick.SecretString{value: raw_value}, _opts) do
    ~s("#{Blick.encrypt_base64!(raw_value)}")
  end
end

defimpl Inspect, for: Blick.SecretString do
  def inspect(%Blick.SecretString{value: _raw_value}, _opts) do
    "<#SecretString>"
  end
end
