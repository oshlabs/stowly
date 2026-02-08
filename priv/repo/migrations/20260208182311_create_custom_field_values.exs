defmodule Stowly.Repo.Migrations.CreateCustomFieldValues do
  use Ecto.Migration

  def change do
    create table(:custom_field_values) do
      add :item_id, references(:items, on_delete: :delete_all), null: false

      add :custom_field_definition_id,
          references(:custom_field_definitions, on_delete: :delete_all), null: false

      add :value, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:custom_field_values, [:item_id, :custom_field_definition_id])
    create index(:custom_field_values, [:custom_field_definition_id])
  end
end
