defmodule Blick.Controller.MaterialTest do
  use ExUnit.Case

  test "GET /api/materials should return 200" do
    %{status: 200, body: body} = Req.get("/api/materials")
    assert Poison.decode!(body) == %{"materials" => []}
  end
end
