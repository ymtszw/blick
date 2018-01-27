defmodule Blick.Controller.MaterialTest do
  use ExUnit.Case

  test "GET /api/material should return 200" do
    %{status: 200, body: body} = Req.get("/api/material")
    assert Poison.decode!(body) == %{"materials" => []}
  end
end