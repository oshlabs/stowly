defmodule StowlyWeb.SearchLive do
  use StowlyWeb, :live_view

  alias Stowly.Search

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Search", query: "", results: [])}
  end

  @impl true
  def handle_params(%{"q" => query}, _url, socket) do
    results = Search.search(query)
    {:noreply, assign(socket, query: query, results: results)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    results = Search.search(query)
    {:noreply, assign(socket, query: query, results: results)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Search
    </.header>

    <form phx-change="search" phx-submit="search" class="mt-4">
      <input
        type="text"
        name="q"
        value={@query}
        placeholder="Search items, tags, categories, locations..."
        class="input input-bordered w-full"
        autofocus
        phx-debounce="300"
      />
    </form>

    <div :if={@query != "" and @results == []} class="text-center py-8 text-base-content/50 mt-4">
      <p>No results found for "{@query}"</p>
    </div>

    <div :if={@results != []} class="mt-6 space-y-2">
      <.link
        :for={item <- @results}
        navigate={~p"/collections/#{item.collection_id}/items/#{item}"}
        class="flex items-center gap-3 p-3 rounded-lg hover:bg-base-200 transition-colors"
      >
        <div class="flex-1">
          <div class="font-medium">{item.name}</div>
          <div class="text-sm text-base-content/70 flex gap-2">
            <span :if={item.collection}>{item.collection.name}</span>
            <span :if={item.category}>/ {item.category.name}</span>
            <span :if={item.storage_location} class="text-base-content/50">
              @ {item.storage_location.name}
            </span>
          </div>
        </div>
        <div class="flex gap-1">
          <span :for={tag <- item.tags} class="badge badge-sm badge-outline">{tag.name}</span>
        </div>
        <span class={[
          "badge badge-sm",
          item.status == "active" && "badge-success",
          item.status == "archived" && "badge-ghost",
          item.status == "lent_out" && "badge-warning",
          item.status == "wishlist" && "badge-info"
        ]}>
          {String.replace(item.status, "_", " ")}
        </span>
      </.link>
    </div>
    """
  end
end
