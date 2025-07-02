defmodule FlamePingMonitor.Monitoring.PingResult do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ping_results" do
    field :status, :string
    field :response_time, :integer
    field :pinged_at, :naive_datetime
    field :error_message, :string
    belongs_to :domain, FlamePingMonitor.Monitoring.Domain

    timestamps()
  end

  @doc false
  def changeset(ping_result, attrs) do
    ping_result
    |> cast(attrs, [:status, :response_time, :pinged_at, :error_message, :domain_id])
    |> validate_required([:status, :pinged_at, :domain_id])
    |> validate_inclusion(:status, ["online", "offline", "timeout"])
    |> foreign_key_constraint(:domain_id)
  end
end
