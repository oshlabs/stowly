defmodule StowlyWeb.HomeLiveTest do
  use StowlyWeb.ConnCase, async: true

  test "renders home page", %{conn: conn} do
    {:ok, _live, html} = live(conn, ~p"/")

    assert html =~ "Stowly"
    assert html =~ "Get Started"
  end
end
