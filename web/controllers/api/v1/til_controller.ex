defmodule TilsioApi.Api.V1.TilController do
  use TilsioApi.Web, :controller

  alias TilsioApi.Til

  def index(conn, _params) do
    tils = Repo.all(Til)

    render(conn, "index.json", data: tils)
  end

  def show(conn, %{"id" => id}) do
    til = Repo.get!(Til, id)

    render(conn, "show.json", data: til)
  end
end
