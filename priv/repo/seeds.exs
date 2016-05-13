alias TilsioApi.Repo
alias TilsioApi.Til

til_attrs1 = %{
  title: "TIL that there is no real JSON standard for iOS apps",
  body: "I learned this after talking to some mobile developers"
}

Til.changeset(%Til{}, til_attrs1) 
|> Repo.insert!

til_attrs2 = %{
  title: "TIL that Ernest Hemingway would stop writing mid-sentence so he knew where to pick it up the other day"
}

Til.changeset(%Til{}, til_attrs2) 
|> Repo.insert!

til_attrs3 = %{
  title: "TIL how to use Erlang's FTP library in Elixir",
  body: "https://github.com/greenfieldhq/til/issues/16"
}

Til.changeset(%Til{}, til_attrs3) 
|> Repo.insert!
