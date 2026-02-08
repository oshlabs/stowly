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
    {:noreply, refresh_locations(socket)}
  end

  def handle_info({StowlyWeb.LocationLive.FormComponent, :deleted}, socket) do
    {:noreply, refresh_locations(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    location = Inventory.get_storage_location!(id)
    {:ok, _} = Inventory.delete_storage_location(location)

    {:noreply,
     socket
     |> put_flash(:info, "Location deleted")
     |> refresh_locations()}
  end

  defp refresh_locations(socket) do
    collection = socket.assigns.collection

    assign(socket,
      locations: Inventory.list_root_storage_locations(collection),
      all_locations: Inventory.list_storage_locations(collection)
    )
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

    <div :if={@locations != []} class="mt-6 overflow-x-auto">
      <table class="table table-sm">
        <thead>
          <tr>
            <th>Name</th>
            <th>Type</th>
            <th>Code</th>
            <th>Items</th>
            <th>Description</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <.location_rows
            locations={@locations}
            collection={@collection}
            level={0}
          />
        </tbody>
      </table>
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

  defp location_rows(assigns) do
    ~H"""
    <%= for location <- @locations do %>
      <tr
        class="hover:bg-base-200 cursor-pointer"
        phx-click={JS.patch(~p"/collections/#{@collection}/locations/#{location}/edit")}
      >
        <td>
          <span style={"padding-left: #{@level * 1.25}rem"} class="font-medium">
            {location.name}
          </span>
        </td>
        <td><span class="badge badge-ghost badge-sm">{location.location_type}</span></td>
        <td class="text-sm opacity-70">{location.code}</td>
        <td>{item_count(location)}</td>
        <td class="text-sm opacity-70 max-w-xs truncate">{location.description}</td>
        <td class="text-right">
          <button
            type="button"
            class="btn btn-ghost btn-xs text-error"
            phx-click="delete"
            phx-value-id={location.id}
            data-confirm="Delete this location?"
          >
            <.icon name="hero-trash" class="h-3 w-3" />
          </button>
        </td>
      </tr>
      <.location_rows
        :if={location.children != [] and Ecto.assoc_loaded?(location.children)}
        locations={location.children}
        collection={@collection}
        level={@level + 1}
      />
    <% end %>
    """
  end

  defp item_count(location) do
    direct = if Ecto.assoc_loaded?(location.items), do: length(location.items), else: 0

    children_count =
      if Ecto.assoc_loaded?(location.children) do
        Enum.sum(Enum.map(location.children, &item_count/1))
      else
        0
      end

    direct + children_count
  end
end
