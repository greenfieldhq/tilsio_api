defmodule TilsioApi.Router do
  use TilsioApi.Web, :router

  pipeline :api do
    plug :accepts, ["json", "json-api"]
    plug JaSerializer.ContentTypeNegotiation
    plug JaSerializer.Deserializer
  end

  scope "/api/v1", TilsioApi.Api.V1 do
    pipe_through :api

    resources "/tils", TilController, only: [:index, :show]
  end
end
