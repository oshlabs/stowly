defmodule Stowly.SearchTest do
  use Stowly.DataCase, async: true

  alias Stowly.Search
  import Stowly.InventoryFixtures

  describe "search/2" do
    test "returns empty list for blank query" do
      assert Search.search("") == []
      assert Search.search("   ") == []
    end

    test "finds items by name" do
      collection = collection_fixture()
      item_fixture(collection, %{name: "Special Laptop"})

      results = Search.search("Laptop")
      assert length(results) == 1
      assert hd(results).name == "Special Laptop"
    end

    test "finds items by description" do
      collection = collection_fixture()
      item_fixture(collection, %{name: "Widget", description: "A unique gizmo for testing"})

      results = Search.search("gizmo")
      assert length(results) == 1
    end

    test "returns empty list for no matches" do
      collection = collection_fixture()
      item_fixture(collection, %{name: "Widget"})

      assert Search.search("nonexistent") == []
    end

    test "scopes by collection_id" do
      c1 = collection_fixture(%{name: "Collection A"})
      c2 = collection_fixture(%{name: "Collection B"})
      item_fixture(c1, %{name: "Laptop A"})
      item_fixture(c2, %{name: "Laptop B"})

      results = Search.search("Laptop", collection_id: c1.id)
      assert length(results) == 1
      assert hd(results).name == "Laptop A"
    end
  end
end
