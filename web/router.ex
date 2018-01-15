defmodule Blick.Router do
  use SolomonLib.Router

  get "/login", Root, :public_login, as: "public_login"

  get "/*path", Root, :index
end
