defmodule Stowly.Repo do
  use Ecto.Repo,
    otp_app: :stowly,
    adapter: Ecto.Adapters.Postgres
end
