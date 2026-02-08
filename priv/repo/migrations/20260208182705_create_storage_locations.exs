defmodule Stowly.Repo.Migrations.CreateStorageLocations do
  use Ecto.Migration

  def change do
    create table(:storage_locations) do
      add :collection_id, references(:collections, on_delete: :delete_all), null: false
      add :parent_id, references(:storage_locations, on_delete: :nilify_all)
      add :name, :string, null: false
      add :slug, :string, null: false
      add :location_type, :string, null: false, default: "other"
      add :description, :text
      add :code, :string
      add :position, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:storage_locations, [:collection_id])
    create index(:storage_locations, [:parent_id])
    create unique_index(:storage_locations, [:collection_id, :slug])
  end
end
