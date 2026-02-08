defmodule StowlyWeb.CollectionLive.Show do
  use StowlyWeb, :live_view

  alias Stowly.Inventory

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    collection = Inventory.get_collection!(id)
    {:ok, assign(socket, collection: collection, page_title: collection.name)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Inventory.delete_collection(socket.assigns.collection)

    {:noreply,
     socket |> put_flash(:info, "Collection deleted") |> push_navigate(to: ~p"/collections")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.theme_applicator theme={@collection.theme} />
    <.back navigate={~p"/collections"}>Collections</.back>

    <.header>
      <span :if={@collection.icon} class="mr-2">{@collection.icon}</span>
      {@collection.name}
      <:subtitle>{@collection.description}</:subtitle>
      <:actions>
        <.link navigate={~p"/collections/#{@collection}/settings"} class="btn btn-ghost btn-sm">
          <.icon name="hero-cog-6-tooth" class="h-4 w-4" /> Settings
        </.link>
        <.link patch={~p"/collections/#{@collection}/edit"} class="btn btn-ghost btn-sm">
          <.icon name="hero-pencil-square" class="h-4 w-4" /> Edit
        </.link>
        <button class="btn btn-ghost btn-sm text-error" phx-click="delete" data-confirm="Are you sure you want to delete this collection?">
          <.icon name="hero-trash" class="h-4 w-4" /> Delete
        </button>
      </:actions>
    </.header>

    <div class="mt-8 grid grid-cols-1 md:grid-cols-3 gap-4">
      <.link
        navigate={~p"/collections/#{@collection}/items"}
        class="card bg-base-200 hover:shadow-lg transition-shadow cursor-pointer"
      >
        <div class="card-body items-center text-center">
          <.icon name="hero-cube" class="h-8 w-8" />
          <h3 class="card-title">Items</h3>
          <p class="text-base-content/70 text-sm">Browse and manage items</p>
        </div>
      </.link>
      <.link
        navigate={~p"/collections/#{@collection}/locations"}
        class="card bg-base-200 hover:shadow-lg transition-shadow cursor-pointer"
      >
        <div class="card-body items-center text-center">
          <.icon name="hero-map-pin" class="h-8 w-8" />
          <h3 class="card-title">Locations</h3>
          <p class="text-base-content/70 text-sm">Storage locations hierarchy</p>
        </div>
      </.link>
      <.link
        navigate={~p"/collections/#{@collection}/labels"}
        class="card bg-base-200 hover:shadow-lg transition-shadow cursor-pointer"
      >
        <div class="card-body items-center text-center">
          <.icon name="hero-tag" class="h-8 w-8" />
          <h3 class="card-title">Labels</h3>
          <p class="text-base-content/70 text-sm">Design and print labels</p>
        </div>
      </.link>
      <.link
        navigate={~p"/collections/#{@collection}/settings"}
        class="card bg-base-200 hover:shadow-lg transition-shadow cursor-pointer"
      >
        <div class="card-body items-center text-center">
          <.icon name="hero-cog-6-tooth" class="h-8 w-8" />
          <h3 class="card-title">Settings</h3>
          <p class="text-base-content/70 text-sm">Categories, tags, custom fields</p>
        </div>
      </.link>
    </div>

    <.modal
      :if={@live_action == :edit}
      id="collection-modal"
      show
      on_cancel={JS.patch(~p"/collections/#{@collection}")}
    >
      <.live_component
        module={StowlyWeb.CollectionLive.FormComponent}
        id={@collection.id}
        title="Edit Collection"
        action={:edit}
        collection={@collection}
        patch={~p"/collections/#{@collection}"}
      />
    </.modal>
    """
  end
end
