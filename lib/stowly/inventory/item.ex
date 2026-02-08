defmodule Stowly.Inventory.Item do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(active archived lent_out wishlist)

  schema "items" do
    field :name, :string
    field :description, :string
    field :quantity, :integer, default: 1
    field :notes, :string
    field :barcode, :string
    field :qr_data, :string
    field :status, :string, default: "active"

    belongs_to :collection, Stowly.Inventory.Collection
    belongs_to :category, Stowly.Inventory.Category
    belongs_to :storage_location, Stowly.Inventory.StorageLocation

    many_to_many :tags, Stowly.Inventory.Tag, join_through: "item_tags", on_replace: :delete
    has_many :custom_field_values, Stowly.Inventory.CustomFieldValue
    has_many :prices, Stowly.Inventory.ItemPrice
    has_many :media, Stowly.Inventory.Medium

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :name,
      :description,
      :quantity,
      :notes,
      :barcode,
      :qr_data,
      :status,
      :category_id,
      :storage_location_id
    ])
    |> validate_required([:name])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:category_id)
  end
end
