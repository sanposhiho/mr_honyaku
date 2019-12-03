# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :mr_honyaku,
  ecto_repos: [MrHonyaku.Repo]

# Configures the endpoint
config :mr_honyaku, MrHonyakuWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "J5bfhv0GSCdLZtLLxvSOJi/FeZrMYbQYFnJuIDqkvLKXQfTzFH2BmTWJtH3LNLuD",
  render_errors: [view: MrHonyakuWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MrHonyaku.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mr_honyaku, :line_auth_token, "7qco1iW1oMODOe/GL9HtBqxxaPvayqwpnABfUJ7pgYlp0yCCX6gyAHLwQhIRXk9Yyu2wGMguVX7JmaKjlf9DiAQHF2xtbWbpf35DcR1HSQY/gTBozEyw0IPZMdvWjERc9NuSjvVffB6JxF7URfYkZwdB04t89/1O/w1cDnyilFU="
config :mr_honyaku, :brain_service_id, "wUjIzhWuLOsDMOU5GMJ2XdMYNCfukH7E"
config :mr_honyaku, :translation_auth, "5b51f2253b1841e9bd4541d33131d4db"


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
