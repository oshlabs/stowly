defmodule Stowly.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Stowly.Inventory` context.
  """

  def unique_collection_name, do: "Collection #{System.unique_integer([:positive])}"
  def unique_category_name, do: "Category #{System.unique_integer([:positive])}"
  def unique_tag_name, do: "Tag #{System.unique_integer([:positive])}"
  def unique_field_name, do: "Field #{System.unique_integer([:positive])}"

  def collection_fixture(attrs \\ %{}) do
    {:ok, collection} =
      attrs
      |> Enum.into(%{
        name: unique_collection_name(),
        description: "A test collection"
      })
      |> Stowly.Inventory.create_collection()

    collection
  end

  def category_fixture(collection, attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{name: unique_category_name()})
      |> then(&Stowly.Inventory.create_category(collection, &1))

    category
  end

  def tag_fixture(collection, attrs \\ %{}) do
    {:ok, tag} =
      attrs
      |> Enum.into(%{name: unique_tag_name()})
      |> then(&Stowly.Inventory.create_tag(collection, &1))

    tag
  end

  def unique_item_name, do: "Item #{System.unique_integer([:positive])}"

  def item_fixture(collection, attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{name: unique_item_name()})
      |> then(&Stowly.Inventory.create_item(collection, &1))

    item
  end

  def item_price_fixture(item, attrs \\ %{}) do
    {:ok, price} =
      attrs
      |> Enum.into(%{amount_cents: 1999, currency: "EUR"})
      |> then(&Stowly.Inventory.create_item_price(item, &1))

    price
  end

  def storage_location_fixture(collection, attrs \\ %{}) do
    {:ok, location} =
      attrs
      |> Enum.into(%{
        name: "Location #{System.unique_integer([:positive])}",
        location_type: "room"
      })
      |> then(&Stowly.Inventory.create_storage_location(collection, &1))

    location
  end

  def custom_field_definition_fixture(collection, attrs \\ %{}) do
    {:ok, field_def} =
      attrs
      |> Enum.into(%{name: unique_field_name(), field_type: "text"})
      |> then(&Stowly.Inventory.create_custom_field_definition(collection, &1))

    field_def
  end
end
