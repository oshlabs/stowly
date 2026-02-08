defmodule Stowly.Inventory.CustomFieldValue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "custom_field_values" do
    field :value, :string

    belongs_to :item, Stowly.Inventory.Item
    belongs_to :custom_field_definition, Stowly.Inventory.CustomFieldDefinition

    timestamps(type: :utc_datetime)
  end

  def changeset(field_value, attrs) do
    field_value
    |> cast(attrs, [:value, :custom_field_definition_id])
    |> validate_required([:custom_field_definition_id])
    |> unique_constraint([:item_id, :custom_field_definition_id])
  end
end
