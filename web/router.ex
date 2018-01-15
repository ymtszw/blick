defmodule Blick.Router do
  use SolomonLib.Router

  get "/*path", Root, :index
end
