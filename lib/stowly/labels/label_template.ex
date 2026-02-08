defmodule Stowly.Labels.LabelTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "label_templates" do
    field :name, :string
    field :description, :string
    field :width_mm, :integer, default: 62
    field :height_mm, :integer, default: 29
    field :template, :map, default: %{}
    field :is_default, :boolean, default: false

    belongs_to :collection, Stowly.Inventory.Collection

    timestamps()
  end

  def changeset(label_template, attrs) do
    label_template
    |> cast(attrs, [:name, :description, :width_mm, :height_mm, :template, :is_default])
    |> validate_required([:name, :width_mm, :height_mm])
    |> validate_number(:width_mm, greater_than: 0)
    |> validate_number(:height_mm, greater_than: 0)
  end
end
