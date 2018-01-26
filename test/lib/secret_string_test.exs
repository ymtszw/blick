defmodule Blick.SecretStringTest do
  use Croma.TestCase, alias_as: SS
  use ExUnitProperties

  property "should accept/reject dicts with plain text on new/1" do
    check all binary <- binary() do
      if String.printable?(binary) do
        assert SS.new( [value: binary]) == {:ok, %SS{value: binary}}
        assert SS.new(%{value: binary}) == {:ok, %SS{value: binary}}
        assert SS.new(%{"value" => binary}) == {:ok, %SS{value: binary}}
      else
        assert SS.new(%{value: binary}) == {:error, {:invalid_value, [Blick.SecretString, {Blick.PrintableString, :value}]}}
      end
    end
  end

  property "should be encrypted on Poison.encode/1" do
    check all binary <- string(:printable) do
      refute Poison.encode!(%SS{value: binary}) == ~s("#{binary}")
    end
  end

  property "should be decrypted on new/1" do
    check all binary <- string(:printable) do
      ss = %SS{value: binary}
      assert ss |> Poison.encode!() |> Poison.decode!() |> SS.new!() == ss
      refute ss |> Poison.encode!() |> Poison.decode!() |> SolomonLib.Crypto.Aes.ctr128_decrypt("wrong key") == ~s("#{binary}")
    end
  end
end
