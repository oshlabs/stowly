defmodule Stowly.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :icon, :string
      add :theme, :map, default: %{}
      add :position, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:collections, [:slug])
  end
end
