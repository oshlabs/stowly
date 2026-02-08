defmodule StowlyWeb.CollectionLive.Index do
  use StowlyWeb, :live_view

  alias Stowly.Inventory
  alias Stowly.Inventory.Collection

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Collections", collections: Inventory.list_collections())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Collection")
    |> assign(:collection, %Collection{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Collection")
    |> assign(:collection, Inventory.get_collection!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:collection, nil)
  end

  @impl true
  def handle_info({StowlyWeb.CollectionLive.FormComponent, {:saved, _collection}}, socket) do
    {:noreply, assign(socket, :collections, Inventory.list_collections())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Collections
      <:actions>
        <.link patch={~p"/collections/new"}>
          <.button class="btn-primary">
            <.icon name="hero-plus" class="h-4 w-4 mr-1" /> New Collection
          </.button>
        </.link>
      </:actions>
    </.header>

    <div :if={@collections == []} class="text-center py-12 text-base-content/50">
      <.icon name="hero-archive-box" class="h-12 w-12 mx-auto mb-4" />
      <p class="text-lg">No collections yet</p>
      <p>Create your first collection to start organizing your inventory.</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
      <.link
        :for={collection <- @collections}
        navigate={~p"/collections/#{collection}"}
        class="card bg-base-200 shadow-md hover:shadow-lg transition-shadow cursor-pointer"
      >
        <div class="card-body">
          <h2 class="card-title">
            <span :if={collection.icon} class="text-2xl">{collection.icon}</span>
            {collection.name}
          </h2>
          <p :if={collection.description} class="text-base-content/70">
            {collection.description}
          </p>
          <div class="card-actions justify-end mt-2">
            <.link
              patch={~p"/collections/#{collection}/edit"}
              class="btn btn-ghost btn-sm"
              phx-click={JS.push("noop")}
            >
              <.icon name="hero-pencil-square" class="h-4 w-4" />
            </.link>
          </div>
        </div>
      </.link>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="collection-modal"
      show
      on_cancel={JS.patch(~p"/collections")}
    >
      <.live_component
        module={StowlyWeb.CollectionLive.FormComponent}
        id={@collection.id || :new}
        title={@page_title}
        action={@live_action}
        collection={@collection}
        patch={~p"/collections"}
      />
    </.modal>
    """
  end
end
