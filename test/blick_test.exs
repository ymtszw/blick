defmodule BlickTest do
  use ExUnit.Case

  test "GET / should render HAML template as HTML" do
    response = Req.get("/")
    assert response.status == 200
    assert response.headers["content-type"] == "text/html"
    body = response.body
    assert String.starts_with?(body, "<!DOCTYPE html>")
    assert String.contains?(body, "Blick")
  end
end
