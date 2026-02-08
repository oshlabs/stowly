defmodule StowlyWeb.ItemLiveTest do
  use StowlyWeb.ConnCase, async: true

  import Stowly.InventoryFixtures

  setup do
    collection = collection_fixture()
    %{collection: collection}
  end

  describe "Index" do
    test "lists all items", %{conn: conn, collection: collection} do
      item = item_fixture(collection, %{name: "My Laptop"})
      {:ok, _live, html} = live(conn, ~p"/collections/#{collection}/items")

      assert html =~ "Items"
      assert html =~ item.name
    end

    test "creates new item", %{conn: conn, collection: collection} do
      {:ok, live, _html} = live(conn, ~p"/collections/#{collection}/items/new")

      assert live
             |> form("#item-form", item: %{name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert live
             |> form("#item-form", item: %{name: "New Widget"})
             |> render_submit()

      assert_patch(live, ~p"/collections/#{collection}/items")

      html = render(live)
      assert html =~ "Item created"
      assert html =~ "New Widget"
    end
  end

  describe "Show" do
    test "displays item", %{conn: conn, collection: collection} do
      item = item_fixture(collection, %{name: "My Laptop", description: "A nice laptop"})
      {:ok, _live, html} = live(conn, ~p"/collections/#{collection}/items/#{item}")

      assert html =~ item.name
      assert html =~ "A nice laptop"
    end

    test "deletes item", %{conn: conn, collection: collection} do
      item = item_fixture(collection)
      {:ok, live, _html} = live(conn, ~p"/collections/#{collection}/items/#{item}")

      {:ok, _live, html} =
        live
        |> element("button[phx-click=delete]")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Item deleted"
    end
  end
end
