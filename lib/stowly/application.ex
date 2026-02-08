defmodule Stowly.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StowlyWeb.Telemetry,
      Stowly.Repo,
      {DNSCluster, query: Application.get_env(:stowly, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Stowly.PubSub},
      # Start a worker by calling: Stowly.Worker.start_link(arg)
      # {Stowly.Worker, arg},
      # Start to serve requests, typically the last entry
      StowlyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Stowly.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StowlyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
