defmodule StowlyWeb.Router do
  use StowlyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StowlyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StowlyWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/search", SearchLive
    live "/settings", SettingsLive

    get "/backup/download", BackupController, :download

    live "/collections", CollectionLive.Index, :index
    live "/collections/new", CollectionLive.Index, :new
    live "/collections/:id/edit", CollectionLive.Index, :edit
    live "/collections/:id", CollectionLive.Show, :show
    live "/collections/:id/show/edit", CollectionLive.Show, :edit
    live "/collections/:id/settings", CollectionLive.Settings, :settings

    live "/collections/:collection_id/items", ItemLive.Index, :index
    live "/collections/:collection_id/items/new", ItemLive.Index, :new
    live "/collections/:collection_id/items/:id/edit", ItemLive.Index, :edit

    live "/collections/:collection_id/locations", LocationLive.Index, :index
    live "/collections/:collection_id/locations/new", LocationLive.Index, :new
    live "/collections/:collection_id/locations/:id/edit", LocationLive.Index, :edit

    live "/collections/:collection_id/labels", LabelLive.Index, :index
    live "/collections/:collection_id/labels/new", LabelLive.Index, :new
    live "/collections/:collection_id/labels/:id/edit", LabelLive.Index, :edit
    live "/collections/:collection_id/labels/:id", LabelLive.Show, :show

    get "/collections/:collection_id/labels/:id/print", LabelController, :print
  end

  scope "/api", StowlyWeb do
    pipe_through :api
  end
end
