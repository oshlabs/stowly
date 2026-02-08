defmodule Stowly.Repo.Migrations.AddStorageLocationToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :storage_location_id, references(:storage_locations, on_delete: :nilify_all)
    end

    create index(:items, [:storage_location_id])
  end
end
