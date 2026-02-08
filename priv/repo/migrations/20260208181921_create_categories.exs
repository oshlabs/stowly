defmodule Stowly.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :collection_id, references(:collections, on_delete: :delete_all), null: false
      add :parent_id, references(:categories, on_delete: :nilify_all)
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :position, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:categories, [:collection_id])
    create index(:categories, [:parent_id])
    create unique_index(:categories, [:collection_id, :slug])
  end
end
