defmodule FlamePingMonitor.Monitoring.Domain do
  use Ecto.Schema
  import Ecto.Changeset

  schema "domains" do
    field :name, :string
    field :url, :string
    field :status, :string, default: "checking"
    field :response_time, :integer
    field :last_ping_at, :naive_datetime
    field :error_message, :string
    field :webhook_url, :string
    field :consecutive_failures, :integer, default: 0
    field :last_failure_at, :utc_datetime
    field :webhook_last_sent_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(domain, attrs) do
    domain
    |> cast(attrs, [
      :name,
      :url,
      :webhook_url,
      :status,
      :response_time,
      :last_ping_at,
      :error_message,
      :consecutive_failures,
      :last_failure_at,
      :webhook_last_sent_at
    ])
    |> validate_required([:name, :url])
    |> validate_url_format()
    |> validate_webhook_url()
    |> unique_constraint(:url)
  end

  defp validate_url_format(changeset) do
    case get_field(changeset, :url) do
      nil ->
        changeset

      url ->
        if String.match?(url, ~r/^https?:\/\//) do
          changeset
        else
          # Auto-prepend http:// if missing
          put_change(changeset, :url, "http://#{url}")
        end
    end
  end

  defp validate_webhook_url(changeset) do
    case get_field(changeset, :webhook_url) do
      nil ->
        changeset

      "" ->
        changeset

      webhook_url ->
        if String.match?(webhook_url, ~r/^https?:\/\//) do
          changeset
        else
          add_error(changeset, :webhook_url, "must be a valid HTTP or HTTPS URL")
        end
    end
  end
end
