defmodule TilsioApi.Api.V1.TilView do
  use TilsioApi.Web, :view
  use JaSerializer.PhoenixView

  location "/tils/:id"

  attributes [
    :title,
    :body
  ]
end
