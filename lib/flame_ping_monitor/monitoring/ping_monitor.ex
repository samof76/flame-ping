defmodule FlamePingMonitor.Monitoring.PingMonitor do
  @moduledoc """
  FLAME-powered distributed ping monitoring system.
  Spawns ping workers across multiple regions/nodes for global coverage.
  """

  alias FlamePingMonitor.Monitoring.{Domain, PingResult}
  alias FlamePingMonitor.Repo
  require Logger
  import Ecto.Query

  @doc """
  Starts distributed ping monitoring for a domain using FLAME.
  """
  def start_ping(domain) do
    Logger.info("Starting FLAME ping for domain: #{domain.name}")

    FLAME.call(FlamePingMonitor.PingRunner, fn ->
      FlamePingMonitor.PingRunner.ping_domain(domain)
    end)
  end

  @doc """
  Starts monitoring all domains in the database.
  """
  def start_monitoring_all do
    domains = Repo.all(Domain)

    for domain <- domains do
      start_ping(domain)
    end

    Logger.info("Started monitoring #{length(domains)} domains")
  end

  @doc """
  Handles ping results from FLAME workers and broadcasts updates.
  """
  def handle_ping_result(domain_id, status, response_time, error_message \\ nil) do
    # Update domain with latest ping result
    domain = Repo.get!(Domain, domain_id)

    update_attrs = %{
      status: status,
      response_time: response_time,
      last_ping_at: NaiveDateTime.utc_now(),
      error_message: error_message
    }

    case domain |> Domain.changeset(update_attrs) |> Repo.update() do
      {:ok, updated_domain} ->
        # Store ping result in history
        create_ping_result(%{
          domain_id: domain_id,
          status: status,
          response_time: response_time,
          pinged_at: NaiveDateTime.utc_now(),
          error_message: error_message
        })

        # Broadcast update to all connected LiveViews
        Phoenix.PubSub.broadcast(
          FlamePingMonitor.PubSub,
          "domain_updates",
          {:ping_update, domain_id, status, response_time}
        )

        Logger.info("Ping result for #{updated_domain.name}: #{status} (#{response_time}ms)")
        {:ok, updated_domain}

      {:error, changeset} ->
        Logger.error("Failed to update domain #{domain_id}: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  @doc """
  Creates a ping result record in the database.
  """
  def create_ping_result(attrs) do
    %PingResult{}
    |> PingResult.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets recent ping results for a domain.
  """
  def get_recent_ping_results(domain_id, limit \\ 50) do
    from(pr in PingResult,
      where: pr.domain_id == ^domain_id,
      order_by: [desc: pr.pinged_at],
      limit: ^limit
    )
    |> Repo.all()
  end
end
