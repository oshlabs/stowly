defmodule StowlyWeb.ItemLive.Show do
  use StowlyWeb, :live_view

  alias Stowly.Inventory

  @impl true
  def mount(%{"collection_id" => collection_id, "id" => id}, _session, socket) do
    collection = Inventory.get_collection!(collection_id)
    item = Inventory.get_item!(id)

    {:ok,
     assign(socket,
       collection: collection,
       item: item,
       page_title: item.name
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    {:ok, _} = Inventory.delete_item(socket.assigns.item)

    {:noreply,
     socket
     |> put_flash(:info, "Item deleted")
     |> push_navigate(to: ~p"/collections/#{socket.assigns.collection}/items")}
  end

  @impl true
  def handle_info({StowlyWeb.ItemLive.FormComponent, {:saved, item}}, socket) do
    item = Inventory.get_item!(item.id)
    {:noreply, assign(socket, item: item, page_title: item.name)}
  end

  defp format_price(amount_cents) when is_integer(amount_cents) do
    euros = div(amount_cents, 100)
    cents = rem(amount_cents, 100)
    "#{euros}.#{String.pad_leading(Integer.to_string(cents), 2, "0")}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.theme_applicator theme={@collection.theme} />
    <.back navigate={~p"/collections/#{@collection}/items"}>Items</.back>

    <.header>
      {@item.name}
      <:subtitle>
        <span class={[
          "badge",
          @item.status == "active" && "badge-success",
          @item.status == "archived" && "badge-ghost",
          @item.status == "lent_out" && "badge-warning",
          @item.status == "wishlist" && "badge-info"
        ]}>
          {String.replace(@item.status, "_", " ")}
        </span>
      </:subtitle>
      <:actions>
        <.link
          patch={~p"/collections/#{@collection}/items/#{@item}/edit"}
          class="btn btn-ghost btn-sm"
        >
          <.icon name="hero-pencil-square" class="h-4 w-4" /> Edit
        </.link>
        <button
          class="btn btn-ghost btn-sm text-error"
          phx-click="delete"
          data-confirm="Delete this item?"
        >
          <.icon name="hero-trash" class="h-4 w-4" /> Delete
        </button>
      </:actions>
    </.header>

    <div class="mt-6 mb-6">
      <.live_component
        module={StowlyWeb.ItemLive.MediaComponent}
        id="item-media"
        item={@item}
      />
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
      <div class="space-y-4">
        <div :if={@item.description} class="prose max-w-none">
          <p>{@item.description}</p>
        </div>

        <div class="stats shadow">
          <div class="stat">
            <div class="stat-title">Quantity</div>
            <div class="stat-value text-lg">{@item.quantity}</div>
          </div>
          <div :if={@item.category} class="stat">
            <div class="stat-title">Category</div>
            <div class="stat-value text-lg">{@item.category.name}</div>
          </div>
        </div>

        <div :if={@item.storage_location} class="text-sm">
          <span class="font-medium">Location:</span>
          <.link
            navigate={~p"/collections/#{@collection}/locations/#{@item.storage_location}"}
            class="link link-hover"
          >
            {@item.storage_location.name}
          </.link>
        </div>

        <div :if={@item.tags != []} class="flex flex-wrap gap-2">
          <span
            :for={tag <- @item.tags}
            class="badge"
            style={tag.color && "background-color: #{tag.color}; color: white; border-color: #{tag.color}"}
          >
            {tag.name}
          </span>
        </div>

        <div :if={@item.notes} class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title text-sm">Notes</h3>
            <p class="text-sm">{@item.notes}</p>
          </div>
        </div>
      </div>

      <div class="space-y-4">
        <div :if={@item.prices != []} class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title text-sm">Prices</h3>
            <div :for={price <- @item.prices} class="flex justify-between items-center py-1 border-b border-base-300 last:border-0">
              <div>
                <span class="font-mono font-bold">
                  {format_price(price.amount_cents)} {price.currency}
                </span>
                <span :if={price.vendor} class="text-sm text-base-content/70 ml-2">
                  @ {price.vendor}
                </span>
              </div>
              <div class="text-sm text-base-content/50">
                <span :if={price.order_quantity}>qty: {price.order_quantity}</span>
              </div>
            </div>
          </div>
        </div>

        <div :if={@item.custom_field_values != []} class="card bg-base-200">
          <div class="card-body">
            <h3 class="card-title text-sm">Custom Fields</h3>
            <div
              :for={cfv <- @item.custom_field_values}
              :if={cfv.value && cfv.value != ""}
              class="flex justify-between py-1"
            >
              <span class="text-sm font-medium">{cfv.custom_field_definition.name}</span>
              <span class="text-sm">{cfv.value}</span>
            </div>
          </div>
        </div>

        <div
          :if={@item.barcode || @item.qr_data}
          class="card bg-base-200"
        >
          <div class="card-body">
            <h3 class="card-title text-sm">Identification</h3>
            <div :if={@item.barcode} class="space-y-2">
              <div class="text-sm">
                <span class="font-medium">Barcode:</span> {@item.barcode}
              </div>
              <StowlyWeb.CodeDisplayComponent.code_display data={@item.barcode} type={:barcode} />
            </div>
            <div :if={@item.qr_data} class="space-y-2">
              <div class="text-sm">
                <span class="font-medium">QR Data:</span> {@item.qr_data}
              </div>
              <StowlyWeb.CodeDisplayComponent.code_display data={@item.qr_data} type={:qr} />
            </div>
          </div>
        </div>
      </div>
    </div>

    <.modal
      :if={@live_action == :edit}
      id="item-modal"
      show
      on_cancel={JS.patch(~p"/collections/#{@collection}/items/#{@item}")}
    >
      <.live_component
        module={StowlyWeb.ItemLive.FormComponent}
        id={@item.id}
        title="Edit Item"
        action={:edit}
        item={@item}
        collection={@collection}
        patch={~p"/collections/#{@collection}/items/#{@item}"}
      />
    </.modal>
    """
  end
end
