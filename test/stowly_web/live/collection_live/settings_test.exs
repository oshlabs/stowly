defmodule StowlyWeb.CollectionLive.SettingsTest do
  use StowlyWeb.ConnCase, async: true

  import Stowly.InventoryFixtures

  setup do
    %{collection: collection_fixture()}
  end

  describe "Settings page" do
    test "renders settings page with tabs", %{conn: conn, collection: collection} do
      {:ok, _live, html} = live(conn, ~p"/collections/#{collection}/settings")

      assert html =~ "Settings"
      assert html =~ "Categories"
      assert html =~ "Tags"
      assert html =~ "Custom Fields"
    end

    test "creates a category", %{conn: conn, collection: collection} do
      {:ok, live, _html} = live(conn, ~p"/collections/#{collection}/settings")

      assert live
             |> form("form", category: %{name: "Electronics"})
             |> render_submit() =~ "Category saved"

      assert render(live) =~ "Electronics"
    end

    test "creates a tag", %{conn: conn, collection: collection} do
      {:ok, live, _html} = live(conn, ~p"/collections/#{collection}/settings?tab=tags")

      assert live
             |> form("form", tag: %{name: "Vintage"})
             |> render_submit() =~ "Tag saved"

      assert render(live) =~ "Vintage"
    end

    test "creates a custom field", %{conn: conn, collection: collection} do
      {:ok, live, _html} = live(conn, ~p"/collections/#{collection}/settings?tab=fields")

      assert live
             |> form("form",
               custom_field_definition: %{name: "Serial Number", field_type: "text"}
             )
             |> render_submit() =~ "Custom field saved"

      assert render(live) =~ "Serial Number"
    end

    test "deletes a category", %{conn: conn, collection: collection} do
      category_fixture(collection, %{name: "ToDelete"})
      {:ok, live, _html} = live(conn, ~p"/collections/#{collection}/settings")

      assert render(live) =~ "ToDelete"

      live
      |> element("button[phx-click=delete_category]")
      |> render_click()

      assert render(live) =~ "Category deleted"
    end
  end
end
