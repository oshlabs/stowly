defmodule StowlyWeb.ItemLive.Index do
  use StowlyWeb, :live_view

  alias Stowly.Inventory
  alias Stowly.Inventory.Item

  @impl true
  def mount(%{"collection_id" => collection_id}, _session, socket) do
    collection = Inventory.get_collection!(collection_id)

    {:ok,
     socket
     |> assign(
       collection: collection,
       page_title: "#{collection.name} - Items",
       categories: Inventory.list_categories(collection),
       tags: Inventory.list_tags(collection),
       filter_category: nil,
       filter_tag: nil,
       filter_status: nil
     )
     |> load_items()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Item")
    |> assign(:item, %Item{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Item")
    |> assign(:item, Inventory.get_item!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:item, nil)
  end

  @impl true
  def handle_event("filter", params, socket) do
    {:noreply,
     socket
     |> assign(
       filter_category: blank_to_nil(params["category_id"]),
       filter_tag: blank_to_nil(params["tag_id"]),
       filter_status: blank_to_nil(params["status"])
     )
     |> load_items()}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    item = Inventory.get_item!(id)
    {:ok, _} = Inventory.delete_item(item)

    {:noreply,
     socket
     |> put_flash(:info, "Item deleted")
     |> load_items()}
  end

  @impl true
  def handle_info({StowlyWeb.ItemLive.FormComponent, {:saved, _item}}, socket) do
    {:noreply, load_items(socket)}
  end

  defp load_items(socket) do
    opts =
      []
      |> maybe_add(:category_id, socket.assigns.filter_category)
      |> maybe_add(:tag_id, socket.assigns.filter_tag)
      |> maybe_add(:status, socket.assigns.filter_status)

    assign(socket, :items, Inventory.list_items(socket.assigns.collection, opts))
  end

  defp maybe_add(opts, _key, nil), do: opts
  defp maybe_add(opts, key, value), do: [{key, value} | opts]

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(val), do: val

  @impl true
  def render(assigns) do
    ~H"""
    <.theme_applicator theme={@collection.theme} />
    <.back navigate={~p"/collections/#{@collection}"}>
      {@collection.name}
    </.back>

    <.header>
      Items
      <:actions>
        <.link patch={~p"/collections/#{@collection}/items/new"}>
          <.button class="btn-primary">
            <.icon name="hero-plus" class="h-4 w-4 mr-1" /> New Item
          </.button>
        </.link>
      </:actions>
    </.header>

    <div class="flex flex-wrap gap-2 mt-4">
      <form phx-change="filter" class="flex flex-wrap gap-2">
        <select name="status" class="select select-bordered select-sm">
          <option value="">All Statuses</option>
          <option :for={s <- Item.statuses()} value={s} selected={@filter_status == s}>
            {String.capitalize(String.replace(s, "_", " "))}
          </option>
        </select>

        <select name="category_id" class="select select-bordered select-sm">
          <option value="">All Categories</option>
          <option
            :for={cat <- @categories}
            value={cat.id}
            selected={@filter_category == to_string(cat.id)}
          >
            {cat.name}
          </option>
        </select>

        <% selected_tag = Enum.find(@tags, &(to_string(&1.id) == @filter_tag)) %>
        <select
          name="tag_id"
          class="select select-bordered select-sm"
          style={selected_tag && selected_tag.color && "color: #{selected_tag.color}; font-weight: 500"}
        >
          <option value="" style="color: inherit; font-weight: normal">All Tags</option>
          <option
            :for={tag <- @tags}
            value={tag.id}
            selected={@filter_tag == to_string(tag.id)}
            style={tag.color && "color: #{tag.color}; font-weight: 500"}
          >
            {tag.name}
          </option>
        </select>
      </form>
    </div>

    <div :if={@items == []} class="text-center py-12 text-base-content/50 mt-4">
      <.icon name="hero-cube" class="h-12 w-12 mx-auto mb-4" />
      <p class="text-lg">No items found</p>
    </div>

    <div class="overflow-x-auto mt-4">
      <table :if={@items != []} class="table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Category</th>
            <th>Status</th>
            <th>Qty</th>
            <th>Tags</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={item <- @items} class="hover">
            <td>
              <.link
                navigate={~p"/collections/#{@collection}/items/#{item}"}
                class="link link-hover font-medium"
              >
                {item.name}
              </.link>
            </td>
            <td>
              <span
                :if={item.category}
                class="badge badge-sm"
                style={item.category.color && "background-color: #{item.category.color}; color: white; border-color: #{item.category.color}"}
              >
                {item.category.name}
              </span>
            </td>
            <td>
              <span class={[
                "badge badge-sm",
                item.status == "active" && "badge-success",
                item.status == "archived" && "badge-ghost",
                item.status == "lent_out" && "badge-warning",
                item.status == "wishlist" && "badge-info"
              ]}>
                {String.replace(item.status, "_", " ")}
              </span>
            </td>
            <td>{item.quantity}</td>
            <td>
              <div class="flex flex-wrap gap-1">
                <span
                  :for={tag <- item.tags}
                  class="badge badge-sm"
                  style={tag.color && "background-color: #{tag.color}; color: white; border-color: #{tag.color}"}
                >
                  {tag.name}
                </span>
              </div>
            </td>
            <td class="flex gap-1 justify-end">
              <.link
                patch={~p"/collections/#{@collection}/items/#{item}/edit"}
                class="btn btn-ghost btn-xs"
              >
                <.icon name="hero-pencil-square" class="h-3 w-3" />
              </.link>
              <button
                class="btn btn-ghost btn-xs text-error"
                phx-click="delete"
                phx-value-id={item.id}
                data-confirm="Delete this item?"
              >
                <.icon name="hero-trash" class="h-3 w-3" />
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="item-modal"
      show
      on_cancel={JS.patch(~p"/collections/#{@collection}/items")}
    >
      <.live_component
        module={StowlyWeb.ItemLive.FormComponent}
        id={@item.id || :new}
        title={@page_title}
        action={@live_action}
        item={@item}
        collection={@collection}
        patch={~p"/collections/#{@collection}/items"}
      />
    </.modal>
    """
  end
end
