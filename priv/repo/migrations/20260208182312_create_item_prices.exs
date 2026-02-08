defmodule Stowly.Repo.Migrations.CreateItemPrices do
  use Ecto.Migration

  def change do
    create table(:item_prices) do
      add :item_id, references(:items, on_delete: :delete_all), null: false
      add :amount_cents, :integer, null: false
      add :currency, :string, null: false, default: "EUR"
      add :vendor, :string
      add :order_quantity, :integer
      add :notes, :string
      add :url, :string

      timestamps(type: :utc_datetime)
    end

    create index(:item_prices, [:item_id])
  end
end
