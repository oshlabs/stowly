defmodule Stowly.Repo.Migrations.CreateLabelTemplates do
  use Ecto.Migration

  def change do
    create table(:label_templates) do
      add :collection_id, references(:collections, on_delete: :delete_all)
      add :name, :string, null: false
      add :description, :text
      add :width_mm, :integer, null: false, default: 62
      add :height_mm, :integer, null: false, default: 29
      add :template, :map, null: false, default: %{}
      add :is_default, :boolean, default: false
      add :target_type, :string, null: false, default: "item"

      timestamps()
    end

    create index(:label_templates, [:collection_id])
  end
end
