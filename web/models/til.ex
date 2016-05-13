defmodule TilsioApi.Til do
  use TilsioApi.Web, :model

  schema "tils" do
    field :title, :string
    field :body, :string

    timestamps
  end

  @required_fields ~w(title)
  @optional_fields ~w(body)

  @doc """
  Creates a changeset based on the `model` and `params`.
  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:title, min: 1)
  end
end
