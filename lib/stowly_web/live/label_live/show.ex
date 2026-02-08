defmodule StowlyWeb.LabelLive.Show do
  use StowlyWeb, :live_view

  alias Stowly.Inventory
  alias Stowly.Labels

  @impl true
  def mount(%{"collection_id" => collection_id, "id" => id}, _session, socket) do
    collection = Inventory.get_collection!(collection_id)
    template = Labels.get_label_template!(id)

    socket =
      socket
      |> assign(
        collection: collection,
        template: template,
        page_title: template.name
      )
      |> load_targets()

    {:ok, socket}
  end

  defp load_targets(socket) do
    collection = socket.assigns.collection
    template = socket.assigns.template

    case template.target_type do
      "location" ->
        locations =
          Inventory.list_storage_locations(collection)
          |> Stowly.Repo.preload(:parent)

        assign(socket,
          locations: locations,
          items: [],
          selected_ids: []
        )

      _ ->
        assign(socket,
          items: Inventory.list_items(collection),
          locations: [],
          selected_ids: []
        )
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_item", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected = socket.assigns.selected_ids

    selected =
      if id in selected do
        List.delete(selected, id)
      else
        selected ++ [id]
      end

    {:noreply, assign(socket, selected_ids: selected)}
  end

  def handle_event("select_all", _params, socket) do
    all =
      if socket.assigns.template.target_type == "location",
        do: socket.assigns.locations,
        else: socket.assigns.items

    {:noreply, assign(socket, selected_ids: Enum.map(all, & &1.id))}
  end

  def handle_event("select_none", _params, socket) do
    {:noreply, assign(socket, selected_ids: [])}
  end

  defp location_template?(assigns), do: assigns.template.target_type == "location"

  @impl true
  def render(assigns) do
    all = if(location_template?(assigns), do: assigns.locations, else: assigns.items)

    assigns =
      assign(assigns,
        all_targets: all,
        preview_targets: Enum.filter(all, &(&1.id in assigns.selected_ids))
      )

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
          :if={@preview_targets != []}
          href={print_href(@collection, @template, @selected_ids)}
          target="_blank"
          class="btn btn-primary btn-sm"
        >
          <.icon name="hero-printer" class="h-4 w-4" /> Print ({length(@preview_targets)})
        </.link>
      </:actions>
    </.header>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
      <div class="lg:col-span-1">
        <h3 class="font-medium mb-2">
          {if @template.target_type == "location", do: "Select Locations", else: "Select Items"}
        </h3>
        <div class="flex gap-2 mb-2">
          <button class="btn btn-ghost btn-xs" phx-click="select_all">Select All</button>
          <button class="btn btn-ghost btn-xs" phx-click="select_none">Clear</button>
        </div>
        <div class="space-y-1 max-h-96 overflow-y-auto">
          <label
            :for={target <- @all_targets}
            class="flex items-center gap-2 p-2 rounded hover:bg-base-200 cursor-pointer"
          >
            <input
              type="checkbox"
              class="checkbox checkbox-sm"
              checked={target.id in @selected_ids}
              phx-click="toggle_item"
              phx-value-id={target.id}
            />
            <span class="text-sm">{target.name}</span>
          </label>
        </div>
      </div>

      <div class="lg:col-span-2">
        <h3 class="font-medium mb-2">Preview</h3>
        <div :if={@preview_targets == []} class="text-center py-8 text-base-content/50">
          {if @template.target_type == "location",
            do: "Select locations to preview labels",
            else: "Select items to preview labels"}
        </div>
        <div class="flex flex-wrap gap-4">
          <div
            :for={target <- @preview_targets}
            class="border border-base-300 rounded p-2 bg-white"
          >
            <p class="text-xs text-base-content/50 mb-1">{target.name}</p>
            {Phoenix.HTML.raw(Labels.render_label(@template, target))}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp print_href(collection, template, selected_ids) do
    param_key = if template.target_type == "location", do: :location_ids, else: :item_ids
    ~p"/collections/#{collection}/labels/#{template}/print?#{%{param_key => selected_ids}}"
  end
end
