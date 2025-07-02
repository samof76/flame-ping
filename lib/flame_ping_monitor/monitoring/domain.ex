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

    timestamps()
  end

  @doc false
  def changeset(domain, attrs) do
    domain
    |> cast(attrs, [:name, :url, :status, :response_time, :last_ping_at, :error_message])
    |> validate_required([:name, :url])
    |> validate_url_format()
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
end
