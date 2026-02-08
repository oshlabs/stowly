defmodule Stowly.Inventory.ItemPrice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "item_prices" do
    field :amount_cents, :integer
    field :currency, :string, default: "EUR"
    field :vendor, :string
    field :order_quantity, :integer
    field :notes, :string
    field :url, :string

    belongs_to :item, Stowly.Inventory.Item

    timestamps(type: :utc_datetime)
  end

  def changeset(price, attrs) do
    price
    |> cast(attrs, [:amount_cents, :currency, :vendor, :order_quantity, :notes, :url])
    |> validate_required([:amount_cents, :currency])
    |> validate_number(:amount_cents, greater_than_or_equal_to: 0)
  end
end
