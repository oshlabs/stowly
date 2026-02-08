defmodule Stowly.Inventory.StorageLocation do
  use Ecto.Schema
  import Ecto.Changeset

  @location_types ~w(room shelf cabinet box tray drawer compartment bin rack other)

  schema "storage_locations" do
    field :name, :string
    field :slug, :string
    field :location_type, :string, default: "other"
    field :description, :string
    field :barcode, :string
    field :qr_data, :string
    field :position, :integer, default: 0

    belongs_to :collection, Stowly.Inventory.Collection
    belongs_to :parent, Stowly.Inventory.StorageLocation
    has_many :children, Stowly.Inventory.StorageLocation, foreign_key: :parent_id
    has_many :items, Stowly.Inventory.Item

    timestamps(type: :utc_datetime)
  end

  def location_types, do: @location_types

  def changeset(location, attrs) do
    location
    |> cast(attrs, [
      :name,
      :location_type,
      :description,
      :barcode,
      :qr_data,
      :position,
      :parent_id
    ])
    |> validate_required([:name, :location_type])
    |> validate_inclusion(:location_type, @location_types)
    |> maybe_generate_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase alphanumeric with dashes"
    )
    |> unique_constraint([:collection_id, :slug],
      error_key: :name,
      message: "a location with this name already exists in this collection"
    )
    |> foreign_key_constraint(:parent_id)
    |> validate_not_self_parent()
  end

  defp validate_not_self_parent(changeset) do
    parent_id = get_field(changeset, :parent_id)
    id = get_field(changeset, :id)

    if parent_id && parent_id == id do
      add_error(changeset, :parent_id, "cannot be its own parent")
    else
      changeset
    end
  end

  defp maybe_generate_slug(changeset) do
    if get_change(changeset, :name) || get_field(changeset, :slug) in [nil, ""] do
      put_change(changeset, :slug, slugify(get_field(changeset, :name)))
    else
      changeset
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
