defmodule TilsioApi.TilControllerTest do
  use TilsioApi.ConnCase
  alias TilsioApi.Til

  test "index action", %{conn: conn} do
    til_attrs1 = %{
      title: "TIL: Phoenix is Great",
      body: "Here is a body"
    }

    til_attrs2 = %{
      title: "TIL: Hemingway would end writing mid-sentence so he'd know where to start the next day"
    }

    til1 = Til.changeset(%Til{}, til_attrs1) |> Repo.insert!
    til2 = Til.changeset(%Til{}, til_attrs2) |> Repo.insert!

    conn = conn
    |> get("/api/v1/tils")

    response = json_response(conn, 200)

    # assert the response is the same as whats in the db
  end

  test "show action", %{conn: conn} do
    til1_attrs = %{
      title: "TIL: Phoenix is Great",
      body: "Here is a body"
    }

    til1 = Til.changeset(%Til{}, til1_attrs) |> Repo.insert!

    conn = conn
    |> get("/api/v1/tils/#{til1.id}")

    response = json_response(conn, 200)

    # assert the response is the same as whats in the db
  end
end
