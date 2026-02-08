defmodule Stowly.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :collection_id, references(:collections, on_delete: :delete_all), null: false
      add :category_id, references(:categories, on_delete: :nilify_all)
      add :name, :string, null: false
      add :description, :text
      add :quantity, :integer, default: 1
      add :notes, :text
      add :code, :string
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create index(:items, [:collection_id])
    create index(:items, [:category_id])
    create index(:items, [:status])
    create index(:items, [:code])
  end
end
