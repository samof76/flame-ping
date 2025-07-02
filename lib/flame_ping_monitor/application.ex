defmodule FlamePingMonitor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FlamePingMonitorWeb.Telemetry,
      FlamePingMonitor.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:flame_ping_monitor, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster,
       query: Application.get_env(:flame_ping_monitor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FlamePingMonitor.PubSub},
      # FLAME pool for distributed ping workers
      {FLAME.Pool, name: FlamePingMonitor.PingRunner, min: 0, max: 10},
      # Start a worker by calling: FlamePingMonitor.Worker.start_link(arg)
      # {FlamePingMonitor.Worker, arg},
      # Ping scheduler for 10-second intervals across all regions
      FlamePingMonitor.Monitoring.PingScheduler,
      # Start to serve requests, typically the last entry
      FlamePingMonitorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FlamePingMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FlamePingMonitorWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
