defmodule Stowly.LabelsTest do
  use Stowly.DataCase

  alias Stowly.Labels
  import Stowly.InventoryFixtures

  describe "label_templates" do
    test "list_label_templates/1 returns templates for a collection" do
      collection = collection_fixture()
      {:ok, template} = Labels.create_label_template(collection, %{name: "Test Label"})

      assert [found] = Labels.list_label_templates(collection)
      assert found.id == template.id
    end

    test "get_label_template!/1 returns a template" do
      collection = collection_fixture()
      {:ok, template} = Labels.create_label_template(collection, %{name: "Test Label"})

      found = Labels.get_label_template!(template.id)
      assert found.id == template.id
    end

    test "create_label_template/2 with valid attrs" do
      collection = collection_fixture()

      assert {:ok, template} =
               Labels.create_label_template(collection, %{
                 name: "Address Label",
                 width_mm: 62,
                 height_mm: 29,
                 template: %{
                   "elements" => [%{"type" => "field", "field" => "name", "x" => 1, "y" => 5}]
                 }
               })

      assert template.name == "Address Label"
      assert template.width_mm == 62
      assert template.collection_id == collection.id
    end

    test "create_label_template/2 requires name" do
      collection = collection_fixture()

      assert {:error, changeset} = Labels.create_label_template(collection, %{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "update_label_template/2 updates fields" do
      collection = collection_fixture()
      {:ok, template} = Labels.create_label_template(collection, %{name: "Old Name"})

      assert {:ok, updated} = Labels.update_label_template(template, %{name: "New Name"})
      assert updated.name == "New Name"
    end

    test "delete_label_template/1 deletes the template" do
      collection = collection_fixture()
      {:ok, template} = Labels.create_label_template(collection, %{name: "Disposable"})

      assert {:ok, _} = Labels.delete_label_template(template)
      assert_raise Ecto.NoResultsError, fn -> Labels.get_label_template!(template.id) end
    end
  end

  describe "render_label/2" do
    test "renders SVG with text elements" do
      collection = collection_fixture()

      {:ok, template} =
        Labels.create_label_template(collection, %{
          name: "Test",
          width_mm: 62,
          height_mm: 29,
          template: %{
            "elements" => [
              %{"type" => "text", "text" => "Hello World", "x" => 1, "y" => 5, "font_size" => 3}
            ]
          }
        })

      item = item_fixture(collection, %{name: "Test Item"})
      item = Stowly.Inventory.get_item!(item.id)

      svg = Labels.render_label(template, item)
      assert svg =~ "<svg"
      assert svg =~ "Hello World"
    end

    test "renders SVG with field elements" do
      collection = collection_fixture()

      {:ok, template} =
        Labels.create_label_template(collection, %{
          name: "Test",
          template: %{
            "elements" => [
              %{
                "type" => "field",
                "field" => "name",
                "x" => 1,
                "y" => 5,
                "font_size" => 4,
                "font_weight" => "bold"
              }
            ]
          }
        })

      item = item_fixture(collection, %{name: "My Widget"})
      item = Stowly.Inventory.get_item!(item.id)

      svg = Labels.render_label(template, item)
      assert svg =~ "My Widget"
      assert svg =~ "font-weight=\"bold\""
    end

    test "renders empty SVG with no elements" do
      collection = collection_fixture()

      {:ok, template} =
        Labels.create_label_template(collection, %{
          name: "Empty",
          template: %{"elements" => []}
        })

      item = item_fixture(collection)
      item = Stowly.Inventory.get_item!(item.id)

      svg = Labels.render_label(template, item)
      assert svg =~ "<svg"
      assert svg =~ "</svg>"
    end
  end
end
