defmodule BlickTest do
  use ExUnit.Case
  use ExUnitProperties

  property "encrypt_base64!/1 should crash on unprintable binary" do
    check all binary <- binary(min_length: 1), !String.printable?(binary) do
      assert_raise RuntimeError, "Only printable characters are supported.", fn ->
        Blick.encrypt_base64!(binary)
      end
    end
  end
end
