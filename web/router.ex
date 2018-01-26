defmodule Blick.Router do
  use SolomonLib.Router

  get "/login", Root, :public_login, as: "public_login"

  get "/admin/authorize", Admin, :authorize, as: "authorize"
  get "/admin/authorize/callback", Admin, :authorize_callback, as: "callback"

  get "/api/material", Material, :list

  get "/", Root, :index
end
