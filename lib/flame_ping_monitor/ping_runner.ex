defmodule FlamePingMonitor.PingRunner do
  @moduledoc """
  FLAME worker module that executes ping operations across distributed nodes.
  """

  require Logger
  alias FlamePingMonitor.Monitoring.PingMonitor

  @doc """
  Pings a domain and returns the result.
  This function runs on FLAME workers for distributed monitoring.
  """
  def ping_domain(domain) do
    ping_domain_from_region(domain, "na")
  end

  @doc """
  Pings a domain from a specific region and returns the result.
  This function runs on FLAME workers for distributed monitoring.
  """
  def ping_domain_from_region(domain, region) do
    Logger.info("FLAME worker pinging: #{domain.url} from region: #{region}")
    start_time = System.monotonic_time(:millisecond)

    case perform_ping(domain.url) do
      {:ok, response_time} ->
        Logger.info("Ping successful for #{domain.name} from #{region}: #{response_time}ms")

        # Send result back to main app with region
        send_ping_result(domain.id, "online", response_time, nil, region)

        {:ok, "online", response_time}

      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        timeout_time = end_time - start_time

        Logger.warning("Ping failed for #{domain.name} from #{region}: #{reason}")

        # Send error result back to main app with region
        send_ping_result(domain.id, "offline", nil, reason, region)

        {:error, "offline", timeout_time, reason}
    end
  end

  defp perform_ping(url) do
    try do
      start_time = System.monotonic_time(:millisecond)

      # Use Req for HTTP ping with timeout
