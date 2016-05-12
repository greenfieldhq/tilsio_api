use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :tilsio_api, TilsioApi.Endpoint,
  secret_key_base: "fQjtOyaSEFlI9WCm/GLQ98NCbmaRIpOt4S+09GHWscZL0ccAC47rO9KC1qBfBPCW"

# Configure your database
config :tilsio_api, TilsioApi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "tilsio_api_prod",
  pool_size: 20
