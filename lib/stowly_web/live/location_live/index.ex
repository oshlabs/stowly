defmodule StowlyWeb.LocationLive.Index do
  use StowlyWeb, :live_view

  alias Stowly.Inventory
  alias Stowly.Inventory.StorageLocation

  @impl true
  def mount(%{"collection_id" => collection_id}, _session, socket) do
    collection = Inventory.get_collection!(collection_id)

    {:ok,
     socket
     |> assign(
       collection: collection,
       page_title: "#{collection.name} - Locations",
       locations: Inventory.list_root_storage_locations(collection),
       all_locations: Inventory.list_storage_locations(collection)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Location")
    |> assign(:location, %StorageLocation{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Location")
    |> assign(:location, Inventory.get_storage_location!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(:location, nil)
  end

  @impl true
  def handle_info({StowlyWeb.LocationLive.FormComponent, {:saved, _location}}, socket) do
    collection = socket.assigns.collection

    {:noreply,
     assign(socket,
       locations: Inventory.list_root_storage_locations(collection),
       all_locations: Inventory.list_storage_locations(collection)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.theme_applicator theme={@collection.theme} />
    <.back navigate={~p"/collections/#{@collection}"}>
      {@collection.name}
    </.back>

    <.header>
      Storage Locations
      <:actions>
        <.link patch={~p"/collections/#{@collection}/locations/new"}>
          <.button class="btn-primary">
            <.icon name="hero-plus" class="h-4 w-4 mr-1" /> New Location
          </.button>
        </.link>
      </:actions>
    </.header>

    <div :if={@locations == []} class="text-center py-12 text-base-content/50 mt-4">
      <.icon name="hero-map-pin" class="h-12 w-12 mx-auto mb-4" />
      <p class="text-lg">No storage locations yet</p>
    </div>

    <div :if={@locations != []} class="mt-6 space-y-2">
      <.location_tree
        locations={@locations}
        collection={@collection}
        level={0}
      />
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="location-modal"
      show
      on_cancel={JS.patch(~p"/collections/#{@collection}/locations")}
    >
      <.live_component
        module={StowlyWeb.LocationLive.FormComponent}
        id={@location.id || :new}
        title={@page_title}
        action={@live_action}
        location={@location}
        collection={@collection}
        all_locations={@all_locations}
        patch={~p"/collections/#{@collection}/locations"}
      />
    </.modal>
    """
  end

  defp location_tree(assigns) do
    ~H"""
    <div :for={location <- @locations} class={"ml-#{@level * 4}"}>
      <div class="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-base-200">
        <.link
          navigate={~p"/collections/#{@collection}/locations/#{location}"}
          class="flex items-center gap-2 flex-1"
        >
          <span class="badge badge-ghost badge-sm">{location.location_type}</span>
          <span class="font-medium">{location.name}</span>
        </.link>
        <.link
          patch={~p"/collections/#{@collection}/locations/#{location}/edit"}
          class="btn btn-ghost btn-xs"
        >
          <.icon name="hero-pencil-square" class="h-3 w-3" />
        </.link>
      </div>
      <.location_tree
        :if={location.children != [] and Ecto.assoc_loaded?(location.children)}
        locations={location.children}
        collection={@collection}
        level={@level + 1}
      />
    </div>
    """
  end
end
