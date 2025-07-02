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
    Logger.info("FLAME worker pinging: #{domain.url}")
    start_time = System.monotonic_time(:millisecond)

    case perform_ping(domain.url) do
      {:ok, response_time} ->
        Logger.info("Ping successful for #{domain.name}: #{response_time}ms")

        # Send result back to main app
        send_ping_result(domain.id, "online", response_time)

        {:ok, "online", response_time}

      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        timeout_time = end_time - start_time

        Logger.warning("Ping failed for #{domain.name}: #{reason}")

        # Send error result back to main app
        send_ping_result(domain.id, "offline", nil, reason)

        {:error, "offline", timeout_time, reason}
    end
  end

  @doc """
  Performs the actual HTTP ping to the domain.
  """
  defp perform_ping(url) do
    try do
      start_time = System.monotonic_time(:millisecond)

      # Use Req for HTTP ping with timeout
      case Req.get(url, connect_options: [timeout: 5000], receive_timeout: 5000) do
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

  @doc """
  Sends ping result back to the main application.
  """
  defp send_ping_result(domain_id, status, response_time, error_message \\ nil) do
    # This would normally send back to the main node
    # For now, we'll call the handler directly
    Task.start(fn ->
      PingMonitor.handle_ping_result(domain_id, status, response_time, error_message)
    end)
  end
end
