defmodule Blick.Router do
  use SolomonLib.Router

  get "/login", Root, :public_login, as: "public_login"

  get "/admin/authorize", Admin, :authorize, as: "authorize"
  get "/admin/authorize/callback", Admin, :authorize_callback, as: "callback"

  get "/api/materials", Material, :list
  get "/api/materials/:id", Material, :get

  get "/api/screenshots/new", Screenshot, :list_new
  post "/api/screenshots/request_upload_start", Screenshot, :request_upload_start

  get "/", Root, :index
  get "/:id", Root, :show

  get "/*path", Root, :fallback
end
