defmodule Blick.Controller.ScreenshotTest do
  use ExUnit.Case

  setup_all do
    %{"worker_key" => wk, "encryption_key" => ek} = Blick.get_all_env()
    api_key = Blick.Plug.Auth.generate_api_key(wk, ek)
    {:ok, %{api_key: api_key}}
  end

  describe "All APIs" do
    test "should reject request without proper worker key" do
      assert %{status: 401} = Req.get("/api/screenshots", %{"authorization" => ""})
      assert %{status: 401} = Req.get("/api/screenshots", %{"authorization" => "randomstring"})
    end
  end

  test "GET /api/screenshots should accept request with proper worker key", %{api_key: ak} do
    # Should hit StubDatastore
    assert %{status: 200, body: body0} = Req.get("/api/screenshots", %{"authorization" => ak})
    assert body0 == Poison.encode!(%{materials: []})

    assert %{status: 200, body: body1} = Req.get("/api/screenshots") # From intra request
    assert body1 == Poison.encode!(%{materials: []})
  end
end
