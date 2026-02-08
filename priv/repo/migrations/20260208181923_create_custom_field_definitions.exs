defmodule Stowly.Repo.Migrations.CreateCustomFieldDefinitions do
  use Ecto.Migration

  def change do
    create table(:custom_field_definitions) do
      add :collection_id, references(:collections, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :field_type, :string, null: false, default: "text"
      add :options, :map, default: %{}
      add :required, :boolean, default: false
      add :position, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:custom_field_definitions, [:collection_id])
    create unique_index(:custom_field_definitions, [:collection_id, :slug])
  end
end
