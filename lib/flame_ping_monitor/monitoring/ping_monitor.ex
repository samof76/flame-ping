defmodule FlamePingMonitor.Monitoring.PingMonitor do
  @moduledoc """
  FLAME-powered distributed ping monitoring system.
  Spawns ping workers across multiple regions/nodes for global coverage.
  """

  alias FlamePingMonitor.Monitoring.{Domain, PingResult, WebhookNotifier}
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
  Enhanced with consecutive failure tracking and webhook notifications.
  """
  def handle_ping_result(domain_id, status, response_time, error_message \\ nil, region \\ "na") do
    # Get current domain state
    domain = Repo.get!(Domain, domain_id)

    # Calculate failure tracking updates
    failure_attrs = calculate_failure_tracking(domain, status)

    update_attrs =
      %{
        status: status,
        response_time: response_time,
        last_ping_at: NaiveDateTime.utc_now(),
        error_message: error_message
      }
      |> Map.merge(failure_attrs)

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

        # Check if we should send webhook notification
        check_and_send_webhook(updated_domain)

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
  Calculates failure tracking attributes based on ping result.
  """
  defp calculate_failure_tracking(domain, status) do
    case status do
      "online" ->
        # Reset failure count on successful ping
        %{
          consecutive_failures: 0,
          last_failure_at: nil
        }

      _failure_status ->
        # Increment failure count and update last failure time
        %{
          consecutive_failures: (domain.consecutive_failures || 0) + 1,
          last_failure_at: DateTime.utc_now()
        }
    end
  end

  @doc """
  Checks if webhook notification should be sent and sends it.
  Triggers on exactly 6 consecutive failures to avoid spam.
  """
  defp check_and_send_webhook(domain) do
    if domain.consecutive_failures == 6 do
      case WebhookNotifier.send_failure_notification(domain) do
        :ok ->
          Logger.info("Webhook notification sent for critical failure: #{domain.name}")

        :error ->
          Logger.error("Failed to send webhook notification for: #{domain.name}")

        :no_webhook_url ->
          Logger.debug("No webhook URL configured for domain: #{domain.name}")
      end
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
