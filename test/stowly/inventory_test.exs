defmodule Stowly.InventoryTest do
  use Stowly.DataCase, async: true

  alias Stowly.Inventory
  alias Stowly.Inventory.Collection
  alias Stowly.Inventory.Category
  alias Stowly.Inventory.Tag
  alias Stowly.Inventory.CustomFieldDefinition
  alias Stowly.Inventory.Item
  alias Stowly.Inventory.ItemPrice
  alias Stowly.Inventory.StorageLocation

  import Stowly.InventoryFixtures

  describe "collections" do
    test "list_collections/0 returns all collections" do
      collection = collection_fixture()
      assert Inventory.list_collections() == [collection]
    end

    test "get_collection!/1 returns the collection with given id" do
      collection = collection_fixture()
      assert Inventory.get_collection!(collection.id) == collection
    end

    test "get_collection_by_slug!/1 returns the collection with given slug" do
      collection = collection_fixture(%{name: "My Electronics"})
      assert Inventory.get_collection_by_slug!("my-electronics") == collection
    end

    test "create_collection/1 with valid data creates a collection" do
      assert {:ok, %Collection{} = collection} =
               Inventory.create_collection(%{name: "Electronics"})

      assert collection.name == "Electronics"
      assert collection.slug == "electronics"
    end

    test "create_collection/1 generates slug from name" do
      {:ok, collection} = Inventory.create_collection(%{name: "My Stamp Collection"})
      assert collection.slug == "my-stamp-collection"
    end

    test "create_collection/1 with duplicate slug fails" do
      collection_fixture(%{name: "Electronics"})

      assert {:error, changeset} = Inventory.create_collection(%{name: "Electronics"})
      assert {"has already been taken", _} = changeset.errors[:slug]
    end

    test "create_collection/1 with missing name fails" do
      assert {:error, changeset} = Inventory.create_collection(%{})
      assert {"can't be blank", _} = changeset.errors[:name]
    end

    test "update_collection/2 with valid data updates the collection" do
      collection = collection_fixture()

      assert {:ok, %Collection{} = updated} =
               Inventory.update_collection(collection, %{name: "Updated Name"})

      assert updated.name == "Updated Name"
    end

    test "delete_collection/1 deletes the collection" do
      collection = collection_fixture()
      assert {:ok, %Collection{}} = Inventory.delete_collection(collection)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_collection!(collection.id) end
    end

    test "change_collection/1 returns a changeset" do
      collection = collection_fixture()
      assert %Ecto.Changeset{} = Inventory.change_collection(collection)
    end
  end

  describe "categories" do
    setup do
      %{collection: collection_fixture()}
    end

    test "list_categories/1 returns all categories for a collection", %{collection: collection} do
      category = category_fixture(collection)
      assert Inventory.list_categories(collection) == [category]
    end

    test "create_category/2 with valid data creates a category", %{collection: collection} do
      assert {:ok, %Category{} = category} =
               Inventory.create_category(collection, %{name: "Laptops"})

      assert category.name == "Laptops"
      assert category.slug == "laptops"
      assert category.collection_id == collection.id
    end

    test "create_category/2 with parent creates subcategory", %{collection: collection} do
      parent = category_fixture(collection, %{name: "Electronics"})

      assert {:ok, %Category{} = child} =
               Inventory.create_category(collection, %{name: "Laptops", parent_id: parent.id})

      assert child.parent_id == parent.id
    end

    test "create_category/2 with duplicate slug in same collection fails", %{
      collection: collection
    } do
      category_fixture(collection, %{name: "Laptops"})

      assert {:error, changeset} = Inventory.create_category(collection, %{name: "Laptops"})
      assert {"has already been taken", _} = changeset.errors[:collection_id]
    end

    test "update_category/2 updates the category", %{collection: collection} do
      category = category_fixture(collection)

      assert {:ok, %Category{} = updated} =
               Inventory.update_category(category, %{name: "Updated"})

      assert updated.name == "Updated"
    end

    test "delete_category/1 deletes the category", %{collection: collection} do
      category = category_fixture(collection)
      assert {:ok, %Category{}} = Inventory.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_category!(category.id) end
    end
  end

  describe "tags" do
    setup do
      %{collection: collection_fixture()}
    end

    test "list_tags/1 returns all tags for a collection", %{collection: collection} do
      tag = tag_fixture(collection)
      assert Inventory.list_tags(collection) == [tag]
    end

    test "create_tag/2 with valid data creates a tag", %{collection: collection} do
      assert {:ok, %Tag{} = tag} = Inventory.create_tag(collection, %{name: "Vintage"})

      assert tag.name == "Vintage"
      assert tag.slug == "vintage"
      assert tag.collection_id == collection.id
    end

    test "create_tag/2 with duplicate slug in same collection fails", %{collection: collection} do
      tag_fixture(collection, %{name: "Vintage"})

      assert {:error, changeset} = Inventory.create_tag(collection, %{name: "Vintage"})
      assert {"has already been taken", _} = changeset.errors[:collection_id]
    end

    test "update_tag/2 updates the tag", %{collection: collection} do
      tag = tag_fixture(collection)
      assert {:ok, %Tag{} = updated} = Inventory.update_tag(tag, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "delete_tag/1 deletes the tag", %{collection: collection} do
      tag = tag_fixture(collection)
      assert {:ok, %Tag{}} = Inventory.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_tag!(tag.id) end
    end
  end

  describe "custom_field_definitions" do
    setup do
      %{collection: collection_fixture()}
    end

    test "list_custom_field_definitions/1 returns all field defs for a collection", %{
      collection: collection
    } do
      field_def = custom_field_definition_fixture(collection)
      assert Inventory.list_custom_field_definitions(collection) == [field_def]
    end

    test "create_custom_field_definition/2 with valid data creates a field def", %{
      collection: collection
    } do
      assert {:ok, %CustomFieldDefinition{} = fd} =
               Inventory.create_custom_field_definition(collection, %{
                 name: "Serial Number",
                 field_type: "text"
               })

      assert fd.name == "Serial Number"
      assert fd.slug == "serial-number"
      assert fd.field_type == "text"
      assert fd.collection_id == collection.id
    end

    test "create_custom_field_definition/2 validates field_type", %{collection: collection} do
      assert {:error, changeset} =
               Inventory.create_custom_field_definition(collection, %{
                 name: "Bad",
                 field_type: "invalid"
               })

      assert {"is invalid", _} = changeset.errors[:field_type]
    end

    test "update_custom_field_definition/2 updates the field def", %{collection: collection} do
      fd = custom_field_definition_fixture(collection)

      assert {:ok, %CustomFieldDefinition{} = updated} =
               Inventory.update_custom_field_definition(fd, %{name: "Updated"})

      assert updated.name == "Updated"
    end

    test "delete_custom_field_definition/1 deletes the field def", %{collection: collection} do
      fd = custom_field_definition_fixture(collection)
      assert {:ok, %CustomFieldDefinition{}} = Inventory.delete_custom_field_definition(fd)

      assert_raise Ecto.NoResultsError, fn ->
        Inventory.get_custom_field_definition!(fd.id)
      end
    end
  end

  describe "items" do
    setup do
      %{collection: collection_fixture()}
    end

    test "list_items/1 returns all items for a collection", %{collection: collection} do
      item = item_fixture(collection)
      items = Inventory.list_items(collection)
      assert length(items) == 1
      assert hd(items).id == item.id
    end

    test "create_item/2 with valid data creates an item", %{collection: collection} do
      assert {:ok, %Item{} = item} =
               Inventory.create_item(collection, %{name: "Laptop", quantity: 2})

      assert item.name == "Laptop"
      assert item.quantity == 2
      assert item.status == "active"
      assert item.collection_id == collection.id
    end

    test "create_item/3 with tags creates item with tag associations", %{
      collection: collection
    } do
      tag = tag_fixture(collection, %{name: "Expensive"})

      assert {:ok, %Item{} = item} =
               Inventory.create_item(collection, %{name: "Laptop"}, [tag.id])

      item = Inventory.get_item!(item.id)
      assert length(item.tags) == 1
      assert hd(item.tags).id == tag.id
    end

    test "update_item/3 updates the item and tags", %{collection: collection} do
      item = item_fixture(collection)
      tag = tag_fixture(collection, %{name: "Updated"})

      assert {:ok, %Item{} = updated} =
               Inventory.update_item(item, %{name: "Updated Laptop"}, [tag.id])

      updated = Inventory.get_item!(updated.id)
      assert updated.name == "Updated Laptop"
      assert length(updated.tags) == 1
    end

    test "delete_item/1 deletes the item", %{collection: collection} do
      item = item_fixture(collection)
      assert {:ok, %Item{}} = Inventory.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Inventory.get_item!(item.id) end
    end

    test "list_items/2 with filters", %{collection: collection} do
      category = category_fixture(collection, %{name: "Electronics"})
      item_fixture(collection, %{name: "Active Item", status: "active", category_id: category.id})
      item_fixture(collection, %{name: "Archived Item", status: "archived"})

      active_items = Inventory.list_items(collection, status: "active")
      assert length(active_items) == 1
      assert hd(active_items).name == "Active Item"

      cat_items = Inventory.list_items(collection, category_id: category.id)
      assert length(cat_items) == 1
    end
  end

  describe "item_prices" do
    setup do
      collection = collection_fixture()
      item = item_fixture(collection)
      %{collection: collection, item: item}
    end

    test "create_item_price/2 creates a price", %{item: item} do
      assert {:ok, %ItemPrice{} = price} =
               Inventory.create_item_price(item, %{
                 amount_cents: 1999,
                 currency: "EUR",
                 vendor: "Amazon"
               })

      assert price.amount_cents == 1999
      assert price.currency == "EUR"
      assert price.vendor == "Amazon"
    end

    test "list_item_prices/1 returns all prices for an item", %{item: item} do
      item_price_fixture(item, %{amount_cents: 1999})
      item_price_fixture(item, %{amount_cents: 2499, vendor: "eBay"})

      prices = Inventory.list_item_prices(item)
      assert length(prices) == 2
    end

    test "delete_item_price/1 deletes a price", %{item: item} do
      price = item_price_fixture(item)
      assert {:ok, %ItemPrice{}} = Inventory.delete_item_price(price)
      assert Inventory.list_item_prices(item) == []
    end
  end

  describe "storage_locations" do
    setup do
      %{collection: collection_fixture()}
    end

    test "list_storage_locations/1 returns all locations for a collection", %{
      collection: collection
    } do
      location = storage_location_fixture(collection)
      locations = Inventory.list_storage_locations(collection)
      assert length(locations) == 1
      assert hd(locations).id == location.id
    end

    test "create_storage_location/2 creates a location", %{collection: collection} do
      assert {:ok, %StorageLocation{} = location} =
               Inventory.create_storage_location(collection, %{
                 name: "Living Room",
                 location_type: "room"
               })

      assert location.name == "Living Room"
      assert location.slug == "living-room"
      assert location.location_type == "room"
    end

    test "create_storage_location/2 with parent creates hierarchy", %{collection: collection} do
      parent = storage_location_fixture(collection, %{name: "Room A"})

      assert {:ok, %StorageLocation{} = child} =
               Inventory.create_storage_location(collection, %{
                 name: "Shelf 1",
                 location_type: "shelf",
                 parent_id: parent.id
               })

      assert child.parent_id == parent.id
    end

    test "storage_location_breadcrumbs/1 builds breadcrumb path", %{collection: collection} do
      room = storage_location_fixture(collection, %{name: "Room A"})

      {:ok, shelf} =
        Inventory.create_storage_location(collection, %{
          name: "Shelf 1",
          location_type: "shelf",
          parent_id: room.id
        })

      breadcrumbs = Inventory.storage_location_breadcrumbs(shelf)
      assert length(breadcrumbs) == 2
      assert hd(breadcrumbs).id == room.id
      assert List.last(breadcrumbs).id == shelf.id
    end

    test "delete_storage_location/1 deletes the location", %{collection: collection} do
      location = storage_location_fixture(collection)
      assert {:ok, %StorageLocation{}} = Inventory.delete_storage_location(location)

      assert_raise Ecto.NoResultsError, fn ->
        Inventory.get_storage_location!(location.id)
      end
    end

    test "cannot set self as parent", %{collection: collection} do
      location = storage_location_fixture(collection)

      assert {:error, changeset} =
               Inventory.update_storage_location(location, %{parent_id: location.id})

      assert {"cannot be its own parent", _} = changeset.errors[:parent_id]
    end
  end
end
