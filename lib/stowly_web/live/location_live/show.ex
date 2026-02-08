defmodule StowlyWeb.LocationLive.Show do
  use StowlyWeb, :live_view

  alias Stowly.Inventory

  @impl true
  def mount(%{"collection_id" => collection_id, "id" => id}, _session, socket) do
    collection = Inventory.get_collection!(collection_id)
    location = Inventory.get_storage_location!(id)
    breadcrumbs = Inventory.storage_location_breadcrumbs(location)

    {:ok,
     assign(socket,
       collection: collection,
       location: location,
       breadcrumbs: breadcrumbs,
       page_title: location.name
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Inventory.delete_storage_location(socket.assigns.location)

    {:noreply,
     socket
     |> put_flash(:info, "Location deleted")
     |> push_navigate(to: ~p"/collections/#{socket.assigns.collection}/locations")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.theme_applicator theme={@collection.theme} />
    <.back navigate={~p"/collections/#{@collection}/locations"}>Locations</.back>

    <div class="breadcrumbs text-sm mb-4">
      <ul>
        <li :for={bc <- @breadcrumbs}>
          <.link navigate={~p"/collections/#{@collection}/locations/#{bc}"}>
            {bc.name}
          </.link>
        </li>
      </ul>
    </div>

    <.header>
      <span class="badge badge-ghost mr-2">{@location.location_type}</span>
      {@location.name}
      <:subtitle>{@location.description}</:subtitle>
      <:actions>
        <.link
          patch={~p"/collections/#{@collection}/locations/#{@location}/edit"}
          class="btn btn-ghost btn-sm"
        >
          <.icon name="hero-pencil-square" class="h-4 w-4" /> Edit
        </.link>
        <button
          class="btn btn-ghost btn-sm text-error"
          phx-click="delete"
          data-confirm="Delete this location and unassign all items?"
        >
          <.icon name="hero-trash" class="h-4 w-4" /> Delete
        </button>
      </:actions>
    </.header>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
      <div :if={@location.children != []}>
        <h3 class="font-bold mb-3">Sub-locations</h3>
        <div class="space-y-1">
          <.link
            :for={child <- @location.children}
            navigate={~p"/collections/#{@collection}/locations/#{child}"}
            class="flex items-center gap-2 py-2 px-3 rounded-lg hover:bg-base-200"
          >
            <span class="badge badge-ghost badge-sm">{child.location_type}</span>
            <span>{child.name}</span>
          </.link>
        </div>
      </div>

      <div>
        <h3 class="font-bold mb-3">Items in this location</h3>
        <div :if={@location.items == []} class="text-base-content/50 text-sm">
          No items stored here
        </div>
        <div class="space-y-1">
          <.link
            :for={item <- @location.items}
            navigate={~p"/collections/#{@collection}/items/#{item}"}
            class="flex items-center gap-2 py-2 px-3 rounded-lg hover:bg-base-200"
          >
            <span class="font-medium">{item.name}</span>
            <span :if={item.category} class="badge badge-ghost badge-sm">
              {item.category.name}
            </span>
          </.link>
        </div>
      </div>
    </div>

    <.modal
      :if={@live_action == :edit}
      id="location-modal"
      show
      on_cancel={JS.patch(~p"/collections/#{@collection}/locations/#{@location}")}
    >
      <.live_component
        module={StowlyWeb.LocationLive.FormComponent}
        id={@location.id}
        title="Edit Location"
        action={:edit}
        location={@location}
        collection={@collection}
        all_locations={Inventory.list_storage_locations(@collection)}
        patch={~p"/collections/#{@collection}/locations/#{@location}"}
      />
    </.modal>
    """
  end
end
