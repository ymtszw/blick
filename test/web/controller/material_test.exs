defmodule Blick.Controller.MaterialTest do
  use ExUnit.Case

  setup_all do
    %{"worker_key" => wk, "encryption_key" => ek} = Blick.get_all_env()
    api_key = Blick.Plug.Auth.generate_api_key(wk, ek)
    {:ok, %{api_key: api_key}}
  end

  describe "All APIs" do
    test "should reject request without proper worker key" do
      assert %{status: 401} = Req.get("/api/materials", %{"authorization" => ""})
      assert %{status: 401} = Req.get("/api/materials", %{"authorization" => "randomstring"})
    end
  end

  test "GET /api/materials should return 200", %{api_key: ak} do
    # Should hit StubDatastore
    %{status: 200, body: body0} = Req.get("/api/materials")
    assert Poison.decode!(body0) == %{"materials" => %{}}

    %{status: 200, body: body1} = Req.get("/api/materials", %{"authorization" => ak})
    assert Poison.decode!(body1) == %{"materials" => %{}}
  end

  test "PUT /api/materials/:id/[field] should reject requests without value", %{api_key: ak} do
    dummy_id = "AAAAAAAAAAAAAAAAAAAAAAAAAA"
    for {field, _} <- Blick.Model.Material.data_fields() do
      assert %{status: 400} = Req.put_json("/api/materials/#{dummy_id}/#{field}", %{}, %{"authorization" => ak})
      assert %{status: 400} = Req.put_json("/api/materials/#{dummy_id}/#{field}", %{"non_value" => "dummy"}, %{"authorization" => ak})
    end
  end
end
