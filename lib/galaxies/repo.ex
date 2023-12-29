defmodule Galaxies.Repo do
  use Ecto.Repo,
    otp_app: :galaxies,
    adapter: Ecto.Adapters.Postgres
end
