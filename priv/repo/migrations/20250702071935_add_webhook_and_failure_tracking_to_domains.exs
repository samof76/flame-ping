defmodule FlamePingMonitor.Repo.Migrations.AddWebhookAndFailureTrackingToDomains do
  use Ecto.Migration

  def change do
    alter table(:domains) do
      add :webhook_url, :string
      add :consecutive_failures, :integer, default: 0
      add :last_failure_at, :utc_datetime
      add :webhook_last_sent_at, :utc_datetime
    end

    create index(:domains, [:consecutive_failures])
    create index(:domains, [:last_failure_at])
  end
end
