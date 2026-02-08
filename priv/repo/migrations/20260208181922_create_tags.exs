defmodule Stowly.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :collection_id, references(:collections, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :color, :string

      timestamps(type: :utc_datetime)
    end

    create index(:tags, [:collection_id])
    create unique_index(:tags, [:collection_id, :slug])
  end
end
