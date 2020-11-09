defmodule Webring.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Webring.Repo,
      # Start the Telemetry supervisor
      WebringWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Webring.PubSub},
      # Start the Endpoint (http/https)
      WebringWeb.Endpoint,
      # Webring stuff
      {Finch, name: :default},
      Webring.FairChance,
      Webring.FeedMe
      # Start a worker by calling: Webring.Worker.start_link(arg)
      # {Webring.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Webring.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WebringWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
