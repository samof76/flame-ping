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
  Starts region-specific ping monitoring for a domain using FLAME.
  """
  def start_region_ping(domain, region) do
    Logger.debug("Starting FLAME ping for domain: #{domain.name} from region: #{region}")

    FLAME.call(FlamePingMonitor.PingRunner, fn ->
      FlamePingMonitor.PingRunner.ping_domain_from_region(domain, region)
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
  def handle_ping_result(domain_id, status, response_time, error_message \\ nil, region \\ "na") do
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
        # Store ping result in history with region
        create_ping_result(%{
          domain_id: domain_id,
          status: status,
          response_time: response_time,
          pinged_at: NaiveDateTime.utc_now(),
          error_message: error_message,
          region: region
        })

        # Broadcast region-specific update to all connected LiveViews
        Phoenix.PubSub.broadcast(
          FlamePingMonitor.PubSub,
          "domain_updates",
          {:region_ping_update, domain_id, region, status, response_time}
        )

        Logger.info(
          "Ping result for #{updated_domain.name} from #{region}: #{status} (#{response_time}ms)"
        )

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

  @doc """
  Gets recent ping results for a domain and region.
  """
  def get_recent_ping_results_by_region(domain_id, region, limit \\ 50) do
    from(pr in PingResult,
      where: pr.domain_id == ^domain_id and pr.region == ^region,
      order_by: [desc: pr.pinged_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Calculates 1-hour availability for a domain in a specific region.
  """
  def calculate_hourly_availability(domain_id, region) do
    one_hour_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-3600, :second)

    results =
      from(pr in PingResult,
        where:
          pr.domain_id == ^domain_id and
            pr.region == ^region and
            pr.pinged_at >= ^one_hour_ago,
        select: pr.status
      )
      |> Repo.all()

    case results do
      [] ->
        0.0

      statuses ->
        online_count = Enum.count(statuses, &(&1 == "online"))
        total_count = length(statuses)
        (online_count / total_count * 100) |> Float.round(1)
    end
  end

  @doc """
  Gets latest ping status for each region for a domain.
  """
  def get_domain_region_status(domain_id) do
    regions = ["na", "eu", "as", "sa", "oc"]

    for region <- regions do
      latest_result =
        from(pr in PingResult,
          where: pr.domain_id == ^domain_id and pr.region == ^region,
          order_by: [desc: pr.pinged_at],
          limit: 1
        )
        |> Repo.one()

      availability = calculate_hourly_availability(domain_id, region)

      {region, latest_result, availability}
    end
  end
end
