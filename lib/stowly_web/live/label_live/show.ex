defmodule StowlyWeb.LabelLive.Show do
  use StowlyWeb, :live_view

  alias Stowly.Inventory
  alias Stowly.Labels

  @impl true
  def mount(%{"collection_id" => collection_id, "id" => id}, _session, socket) do
    collection = Inventory.get_collection!(collection_id)
    template = Labels.get_label_template!(id)
    items = Inventory.list_items(collection)

    {:ok,
     assign(socket,
       collection: collection,
       template: template,
       items: items,
       selected_item_ids: [],
       page_title: template.name
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_item", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected = socket.assigns.selected_item_ids

    selected =
      if id in selected do
        List.delete(selected, id)
      else
        selected ++ [id]
      end

    {:noreply, assign(socket, selected_item_ids: selected)}
  end

  def handle_event("select_all", _params, socket) do
    ids = Enum.map(socket.assigns.items, & &1.id)
    {:noreply, assign(socket, selected_item_ids: ids)}
  end

  def handle_event("select_none", _params, socket) do
    {:noreply, assign(socket, selected_item_ids: [])}
  end

  defp selected_items(items, selected_ids) do
    Enum.filter(items, &(&1.id in selected_ids))
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, :preview_items, selected_items(assigns.items, assigns.selected_item_ids))

    ~H"""
    <.theme_applicator theme={@collection.theme} />
    <.back navigate={~p"/collections/#{@collection}/labels"}>Label Templates</.back>

    <.header>
      {@template.name}
      <:subtitle>
        {String.trim(@template.description || "")}
        <span class="text-sm text-base-content/50">
          ({@template.width_mm}mm x {@template.height_mm}mm)
        </span>
      </:subtitle>
      <:actions>
        <.link
          :if={@preview_items != []}
          href={~p"/collections/#{@collection}/labels/#{@template}/print?#{%{item_ids: @selected_item_ids}}"}
          target="_blank"
          class="btn btn-primary btn-sm"
        >
          <.icon name="hero-printer" class="h-4 w-4" /> Print ({length(@preview_items)})
        </.link>
      </:actions>
    </.header>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
      <div class="lg:col-span-1">
        <h3 class="font-medium mb-2">Select Items</h3>
        <div class="flex gap-2 mb-2">
          <button class="btn btn-ghost btn-xs" phx-click="select_all">Select All</button>
          <button class="btn btn-ghost btn-xs" phx-click="select_none">Clear</button>
        </div>
        <div class="space-y-1 max-h-96 overflow-y-auto">
          <label
            :for={item <- @items}
            class="flex items-center gap-2 p-2 rounded hover:bg-base-200 cursor-pointer"
          >
            <input
              type="checkbox"
              class="checkbox checkbox-sm"
              checked={item.id in @selected_item_ids}
              phx-click="toggle_item"
              phx-value-id={item.id}
            />
            <span class="text-sm">{item.name}</span>
          </label>
        </div>
      </div>

      <div class="lg:col-span-2">
        <h3 class="font-medium mb-2">Preview</h3>
        <div :if={@preview_items == []} class="text-center py-8 text-base-content/50">
          Select items to preview labels
        </div>
        <div class="flex flex-wrap gap-4">
          <div :for={item <- @preview_items} class="border border-base-300 rounded p-2 bg-white">
            <p class="text-xs text-base-content/50 mb-1">{item.name}</p>
            {Phoenix.HTML.raw(Labels.render_label(@template, item))}
          </div>
        </div>
      </div>
    </div>
    """
  end
end
