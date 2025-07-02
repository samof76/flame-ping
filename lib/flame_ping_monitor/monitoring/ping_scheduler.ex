defmodule FlamePingMonitor.Monitoring.PingScheduler do
  @moduledoc """
  GenServer that schedules and manages periodic pings for all domains across all regions.
  Pings every domain every 10 seconds from 5 different regions.
  """

  use GenServer
  require Logger
  alias FlamePingMonitor.Monitoring.{Domain, PingMonitor}
  alias FlamePingMonitor.Repo
  import Ecto.Query

  # Ping every 10 seconds
  @ping_interval 10_000

  # 5 regions: North America, Europe, Asia, South America, Oceania
  @regions ["na", "eu", "as", "sa", "oc"]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info(
      "PingScheduler started - will ping every #{@ping_interval}ms from #{length(@regions)} regions"
    )

    # Schedule the first ping cycle
    schedule_next_ping()

    {:ok, %{}}
  end

  @impl true
  def handle_info(:ping_all_domains, state) do
    Logger.debug("Starting ping cycle for all domains across all regions")

    # Get all domains
    domains = Repo.all(from d in Domain, order_by: [asc: d.id])

    # Ping each domain from each region
    for domain <- domains, region <- @regions do
      Task.start(fn ->
        PingMonitor.start_region_ping(domain, region)
      end)
    end

    Logger.debug("Scheduled #{length(domains) * length(@regions)} pings")

    # Schedule next ping cycle
    schedule_next_ping()

    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("PingScheduler received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp schedule_next_ping do
    Process.send_after(self(), :ping_all_domains, @ping_interval)
  end

  @doc """
  Manually trigger a ping cycle for all domains (useful for testing).
  """
  def trigger_ping_cycle do
    send(__MODULE__, :ping_all_domains)
  end

  @doc """
  Get the list of supported regions.
  """
  def regions, do: @regions

  @doc """
  Get region display names for UI.
  """
  def region_names do
    %{
      "na" => "North America",
      "eu" => "Europe",
      "as" => "Asia",
      "sa" => "South America",
      "oc" => "Oceania"
    }
  end

  @doc """
  Get region flags for UI display.
  """
  def region_flags do
    %{
      "na" => "🇺🇸",
      "eu" => "🇪🇺",
      "as" => "🇯🇵",
      "sa" => "🇧🇷",
      "oc" => "🇦🇺"
    }
  end
end
