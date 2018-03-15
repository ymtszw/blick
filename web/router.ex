defmodule Blick.Router do
  use SolomonLib.Router

  get "/login", Root, :public_login, as: "public_login"

  get "/admin/authorize", Admin, :authorize, as: "authorize"
  get "/admin/authorize/callback", Admin, :authorize_callback, as: "callback"

  get "/api/materials", Material, :list
  get "/api/materials/:id", Material, :get
  for {field, _} <- Blick.Model.Material.data_fields() do
    put "/api/materials/:id/#{field}", Material, :"update_#{field}"
  end

  get "/api/screenshots", Screenshot, :list
  post "/api/screenshots/:id/request_upload_start", Screenshot, :request_upload_start
  post "/api/screenshots/:id/notify_upload_finish", Screenshot, :notify_upload_finish

  get "/api/members", Member, :list

  get "/", Root, :index
  get "/:id", Root, :show

  get "/*path", Root, :fallback
end
