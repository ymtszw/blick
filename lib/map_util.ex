use Croma

defmodule Blick.MapUtil do
  defun deep_merge(left :: v[map], right :: v[map]) :: map do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left, right) when is_map(left) and is_map(right) do
    deep_merge(left, right)
  end
  defp deep_resolve(_key, _left, right) do
    right
  end
end
