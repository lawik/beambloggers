defmodule Webring.Repo do
  use Ecto.Repo,
    otp_app: :webring,
    adapter: Ecto.Adapters.Postgres
end
