defmodule Blick.Controller.RootTest do
  use ExUnit.Case

  test "GET / should render HAML template as HTML" do
    %{status: 200, body: "<!DOCTYPE html>" <> _ = body} = Req.get("/")
    assert String.contains?(body, "Blick")
  end
end
