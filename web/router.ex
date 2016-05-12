defmodule TilsioApi.Router do
  use TilsioApi.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TilsioApi do
    pipe_through :api
  end
end
