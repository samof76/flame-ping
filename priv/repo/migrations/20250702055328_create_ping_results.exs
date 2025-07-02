defmodule FlamePingMonitor.Repo.Migrations.CreatePingResults do
  use Ecto.Migration

  def change do
    create table(:ping_results) do
      add :status, :string, null: false
      add :response_time, :integer
      add :pinged_at, :naive_datetime, null: false
      add :error_message, :text
      add :domain_id, references(:domains, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:ping_results, [:domain_id])
    create index(:ping_results, [:pinged_at])
    create index(:ping_results, [:status])
  end
end
