defmodule FlamePingMonitor.Repo.Migrations.AddRegionToPingResults do
  use Ecto.Migration

  def change do
    alter table(:ping_results) do
      add :region, :string, null: false, default: "na"
    end

    create index(:ping_results, [:region])
    create index(:ping_results, [:domain_id, :region])
    create index(:ping_results, [:domain_id, :region, :pinged_at])
  end
end
