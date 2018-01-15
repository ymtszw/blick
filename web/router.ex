defmodule Blick.Router do
  use SolomonLib.Router

  get "/hello", Hello, :hello
end
