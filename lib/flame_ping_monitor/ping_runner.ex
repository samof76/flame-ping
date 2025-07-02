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

      # Use browser headers to avoid bot detection
      headers = [
        {"user-agent",
         "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"},
        {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"},
        {"accept-language", "en-US,en;q=0.5"},
        {"accept-encoding", "gzip, deflate, br"},
        {"dnt", "1"},
        {"connection", "keep-alive"},
        {"upgrade-insecure-requests", "1"}
      ]

      case Req.get(url, headers: headers, connect_options: [timeout: 5000], receive_timeout: 5000) do
        {:ok, %{status: status}} when status in 200..299 ->
          end_time = System.monotonic_time(:millisecond)
          response_time = end_time - start_time
          {:ok, response_time}

        {:ok, %{status: status}} ->
          {:error, "HTTP #{status}"}

        {:error, %{reason: reason}} ->
          {:error, "Connection failed: #{inspect(reason)}"}

        {:error, reason} ->
          {:error, "Request failed: #{inspect(reason)}"}
      end
    rescue
      e ->
        {:error, "Exception: #{inspect(e)}"}
    end
  end

  defp send_ping_result(domain_id, status, response_time, error_message, region) do
    # This would normally send back to the main node
    # For now, we'll call the handler directly
    Task.start(fn ->
      PingMonitor.handle_ping_result(domain_id, status, response_time, error_message, region)
    end)
  end
end
