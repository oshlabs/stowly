defmodule Stowly.BackupTest do
  use Stowly.DataCase

  alias Stowly.Backup
  alias Stowly.Inventory
  import Stowly.InventoryFixtures

  describe "create_backup/1" do
    test "creates a .tgz archive with data" do
      collection = collection_fixture(%{name: "Backup Test"})
      _item = item_fixture(collection, %{name: "Backup Item"})

      assert {:ok, path, filename} = Backup.create_backup()
      assert File.exists?(path)
      assert String.ends_with?(filename, ".tgz")

      File.rm(path)
    end

    test "archive contains manifest and data files" do
      _collection = collection_fixture()

      {:ok, path, _filename} = Backup.create_backup()

      {:ok, file_list} = :erl_tar.table(String.to_charlist(path), [:compressed])
      names = Enum.map(file_list, &List.to_string/1)

      assert "manifest.json" in names
      assert "data/collections.json" in names
      assert "data/items.json" in names

      File.rm(path)
    end
  end

  describe "restore_backup/1" do
    test "round-trips data through backup and restore" do
      collection = collection_fixture(%{name: "Round Trip"})
      item = item_fixture(collection, %{name: "Preserved Item"})
      tag = tag_fixture(collection, %{name: "Important"})
      _price = item_price_fixture(item, %{amount_cents: 4999})

      {:ok, path, _} = Backup.create_backup()

      # Delete all data
      Inventory.delete_item(item)
      Inventory.delete_tag(tag)
      Inventory.delete_collection(collection)

      assert Inventory.list_collections() == []

      # Restore
      assert :ok = Backup.restore_backup(path)

      collections = Inventory.list_collections()
      assert length(collections) == 1
      assert hd(collections).name == "Round Trip"

      File.rm(path)
    end

    test "returns error for invalid archive" do
      tmp = Path.join(System.tmp_dir!(), "invalid_#{System.unique_integer([:positive])}.tgz")
      File.write!(tmp, "not a tar file")

      result = Backup.restore_backup(tmp)
      assert result != :ok

      File.rm(tmp)
    end
  end
end
