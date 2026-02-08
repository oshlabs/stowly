defmodule Stowly.Inventory.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collections" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :icon, :string
    field :theme, :map, default: %{}
    field :position, :integer, default: 0

    has_many :categories, Stowly.Inventory.Category
    has_many :tags, Stowly.Inventory.Tag
    has_many :custom_field_definitions, Stowly.Inventory.CustomFieldDefinition
    has_many :items, Stowly.Inventory.Item
    has_many :storage_locations, Stowly.Inventory.StorageLocation

    timestamps(type: :utc_datetime)
  end

  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name, :description, :icon, :theme, :position])
    |> validate_required([:name])
    |> maybe_generate_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase alphanumeric with dashes"
    )
    |> unique_constraint(:slug)
  end

  defp maybe_generate_slug(changeset) do
    case get_field(changeset, :slug) do
      nil -> put_change(changeset, :slug, slugify(get_field(changeset, :name)))
      "" -> put_change(changeset, :slug, slugify(get_field(changeset, :name)))
      _existing -> changeset
    end
  end

  defp slugify(nil), do: ""

  defp slugify(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/[\s_]+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
