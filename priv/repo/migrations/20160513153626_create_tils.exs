defmodule TilsioApi.Repo.Migrations.CreateTils do
  use Ecto.Migration

  def change do
    create table(:tils) do
      add :title, :string
      add :body, :text

      timestamps
    end
  end
end
