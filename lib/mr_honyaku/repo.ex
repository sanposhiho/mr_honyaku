defmodule MrHonyaku.Repo do
  use Ecto.Repo,
    otp_app: :mr_honyaku,
    adapter: Ecto.Adapters.Postgres
end
