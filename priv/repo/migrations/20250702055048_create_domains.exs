defmodule FlamePingMonitor.Repo.Migrations.CreateDomains do
  use Ecto.Migration

  def change do
    create table(:domains) do
      add :name, :string, null: false
      add :url, :string, null: false
      add :status, :string, default: "checking"
      add :response_time, :integer
      add :last_ping_at, :naive_datetime
      add :error_message, :text

      timestamps()
    end

    create unique_index(:domains, [:url])
    create index(:domains, [:status])
  end
end
