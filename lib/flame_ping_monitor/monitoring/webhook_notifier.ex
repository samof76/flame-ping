defmodule FlamePingMonitor.Monitoring.WebhookNotifier do
  @moduledoc """
  Handles webhook notifications for domain failures.
  Sends HTTP POST requests with JSON payload when domains fail consecutively.
  """

  require Logger
  alias FlamePingMonitor.Monitoring.Domain
  alias FlamePingMonitor.Repo

  @doc """
  Sends a webhook notification for a domain that has failed consecutively.
  """
  def send_failure_notification(domain) do
    if domain.webhook_url && domain.webhook_url != "" do
      payload = build_failure_payload(domain)

      case send_webhook(domain.webhook_url, payload) do
        {:ok, _response} ->
          update_webhook_sent_timestamp(domain)
          Logger.info("Webhook notification sent successfully for domain: #{domain.url}")
          :ok

        {:error, reason} ->
          Logger.error("Failed to send webhook for domain #{domain.url}: #{inspect(reason)}")
          :error
      end
    else
      :no_webhook_url
    end
  end

  defp build_failure_payload(domain) do
    %{
      domain: domain.url,
      name: domain.name,
      status: "critical_failure",
      consecutive_failures: domain.consecutive_failures,
      last_failure_at: domain.last_failure_at,
      error_message: domain.error_message,
      timestamp: DateTime.utc_now()
    }
  end

  defp send_webhook(webhook_url, payload) do
    headers = [{"content-type", "application/json"}]
    body = Jason.encode!(payload)

    Req.post(webhook_url, body: body, headers: headers, receive_timeout: 10_000)
  end

  defp update_webhook_sent_timestamp(domain) do
    domain
    |> Domain.changeset(%{webhook_last_sent_at: DateTime.utc_now()})
    |> Repo.update()
  end
end
