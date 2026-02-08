defmodule StowlyWeb.CollectionLiveTest do
  use StowlyWeb.ConnCase, async: true

  import Stowly.InventoryFixtures

  describe "Index" do
    test "lists all collections", %{conn: conn} do
      collection = collection_fixture(%{name: "My Electronics"})
      {:ok, _live, html} = live(conn, ~p"/collections")

      assert html =~ "Collections"
      assert html =~ collection.name
    end

    test "creates new collection", %{conn: conn} do
      {:ok, live, _html} = live(conn, ~p"/collections/new")

      assert live
             |> form("#collection-form", collection: %{name: ""})
             |> render_change() =~ "can&#39;t be blank"

      assert live
             |> form("#collection-form", collection: %{name: "Stamps"})
             |> render_submit()

      assert_patch(live, ~p"/collections")

      html = render(live)
      assert html =~ "Collection created"
      assert html =~ "Stamps"
    end

    test "updates collection in listing", %{conn: conn} do
      collection = collection_fixture(%{name: "Old Name"})
      {:ok, live, _html} = live(conn, ~p"/collections/#{collection}/edit")

      assert live
             |> form("#collection-form", collection: %{name: "New Name"})
             |> render_submit()

      assert_patch(live, ~p"/collections")

      html = render(live)
      assert html =~ "Collection updated"
      assert html =~ "New Name"
    end
  end

  describe "Show" do
    test "displays collection", %{conn: conn} do
      collection = collection_fixture(%{name: "My Electronics", description: "All my gadgets"})
      {:ok, _live, html} = live(conn, ~p"/collections/#{collection}")

      assert html =~ collection.name
      assert html =~ "All my gadgets"
    end

    test "deletes collection", %{conn: conn} do
      collection = collection_fixture()
      {:ok, live, _html} = live(conn, ~p"/collections/#{collection}")

      {:ok, _live, html} =
        live
        |> element("button[phx-click=delete]")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Collection deleted"
    end
  end
end
