defmodule StowlyWeb.ItemLive.FormComponent do
  use StowlyWeb, :live_component

  alias Stowly.Inventory
  alias Stowly.Inventory.Item

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-h-[80vh] overflow-y-auto">
      <h3 class="text-lg font-bold mb-4">{@title}</h3>

      <.simple_form
        for={@form}
        id="item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%!-- Basic Info - always visible --%>
        <div class="space-y-3">
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:description]} type="textarea" label="Description" />

          <div class="grid grid-cols-2 gap-3">
            <.input field={@form[:quantity]} type="number" label="Quantity" min="0" />
            <.input field={@form[:status]} type="select" label="Status">
              <option :for={s <- Item.statuses()} value={s}>
                {String.capitalize(String.replace(s, "_", " "))}
              </option>
            </.input>
          </div>

          <.input field={@form[:category_id]} type="select" label="Category">
            <option value="">None</option>
            <option :for={cat <- @categories} value={cat.id}>{cat.name}</option>
          </.input>

          <.input field={@form[:storage_location_id]} type="select" label="Storage Location">
            <option value="">None</option>
            <option :for={loc <- @storage_locations} value={loc.id}>
              {loc.name} ({loc.location_type})
            </option>
          </.input>
        </div>

        <%!-- Tags --%>
        <div class="mt-4">
          <label class="fieldset-label">Tags</label>
          <div class="flex flex-wrap gap-2 mt-1">
            <label :for={tag <- @tags} class="label cursor-pointer gap-1">
              <input
                type="checkbox"
                name="tag_ids[]"
                value={tag.id}
                checked={tag.id in @selected_tag_ids}
                class="checkbox checkbox-sm"
              />
              <span class="label-text text-sm">{tag.name}</span>
            </label>
          </div>
          <input type="hidden" name="tag_ids[]" value="" />
        </div>

        <%!-- Prices - collapsible --%>
        <div :if={@show_prices or @prices != []} class="collapse collapse-arrow bg-base-200 mt-4">
          <input type="checkbox" checked={@show_prices} phx-click="toggle_prices" phx-target={@myself} />
          <div class="collapse-title font-medium">
            Prices ({length(@prices)})
          </div>
          <div class="collapse-content">
            <div :for={{price, idx} <- Enum.with_index(@prices)} class="flex gap-2 items-end mb-2">
              <div class="flex-1">
                <label class="fieldset-label text-xs">Amount (cents)</label>
                <input
                  type="number"
                  name={"prices[#{idx}][amount_cents]"}
                  value={price.amount_cents}
                  class="input input-bordered input-sm w-full"
                  min="0"
                />
              </div>
              <div class="w-20">
                <label class="fieldset-label text-xs">Currency</label>
                <input
                  type="text"
                  name={"prices[#{idx}][currency]"}
                  value={price.currency || "EUR"}
                  class="input input-bordered input-sm w-full"
                />
              </div>
              <div class="flex-1">
                <label class="fieldset-label text-xs">Vendor</label>
                <input
                  type="text"
                  name={"prices[#{idx}][vendor]"}
                  value={price.vendor}
                  class="input input-bordered input-sm w-full"
                />
              </div>
              <button
                type="button"
                class="btn btn-ghost btn-sm text-error"
                phx-click="remove_price"
                phx-value-index={idx}
                phx-target={@myself}
              >
                <.icon name="hero-x-mark" class="h-4 w-4" />
              </button>
            </div>
            <button
              type="button"
              class="btn btn-ghost btn-sm mt-2"
              phx-click="add_price"
              phx-target={@myself}
            >
              <.icon name="hero-plus" class="h-4 w-4" /> Add Price
            </button>
          </div>
        </div>

        <button
          :if={!@show_prices and @prices == []}
          type="button"
          class="btn btn-ghost btn-sm mt-2"
          phx-click="toggle_prices"
          phx-target={@myself}
        >
          <.icon name="hero-currency-dollar" class="h-4 w-4" /> Add Prices
        </button>

        <%!-- Custom Fields - collapsible --%>
        <div
          :if={@field_definitions != []}
          class="collapse collapse-arrow bg-base-200 mt-4"
        >
          <input type="checkbox" checked={@show_custom_fields} phx-click="toggle_custom_fields" phx-target={@myself} />
          <div class="collapse-title font-medium">
            Custom Fields ({length(@field_definitions)})
          </div>
          <div class="collapse-content space-y-2">
            <div :for={fd <- @field_definitions}>
              <label class="fieldset-label text-sm">{fd.name}</label>
              <input
                type={field_html_type(fd.field_type)}
                name={"custom_fields[#{fd.id}]"}
                value={Map.get(@custom_field_values, fd.id, "")}
                class="input input-bordered input-sm w-full"
              />
            </div>
          </div>
        </div>

        <%!-- Identification - collapsible --%>
        <div class="collapse collapse-arrow bg-base-200 mt-4">
          <input type="checkbox" checked={@show_identification} phx-click="toggle_identification" phx-target={@myself} />
          <div class="collapse-title font-medium">Identification</div>
          <div class="collapse-content space-y-2">
            <.input field={@form[:barcode]} type="text" label="Barcode" />
            <.input field={@form[:qr_data]} type="text" label="QR Data" />
          </div>
        </div>

        <:actions>
          <.button type="submit" class="btn-primary" phx-disable-with="Saving...">
            Save Item
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp field_html_type("number"), do: "number"
  defp field_html_type("decimal"), do: "number"
  defp field_html_type("date"), do: "date"
  defp field_html_type("boolean"), do: "checkbox"
  defp field_html_type("email"), do: "email"
  defp field_html_type("url"), do: "url"
  defp field_html_type(_), do: "text"

  @impl true
  def update(%{item: item, collection: collection} = assigns, socket) do
    categories = Inventory.list_categories(collection)
    tags = Inventory.list_tags(collection)
    field_definitions = Inventory.list_custom_field_definitions(collection)
    storage_locations = Inventory.list_storage_locations(collection)

    selected_tag_ids =
      if Ecto.assoc_loaded?(item.tags) do
        Enum.map(item.tags, & &1.id)
      else
        []
      end

    custom_field_values =
      if Ecto.assoc_loaded?(item.custom_field_values) do
        Map.new(item.custom_field_values, fn cfv ->
          {cfv.custom_field_definition_id, cfv.value}
        end)
      else
        %{}
      end

    prices =
      if Ecto.assoc_loaded?(item.prices) do
        Enum.map(item.prices, &Map.from_struct/1)
      else
        []
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       categories: categories,
       tags: tags,
       field_definitions: field_definitions,
       storage_locations: storage_locations,
       selected_tag_ids: selected_tag_ids,
       custom_field_values: custom_field_values,
       prices: prices,
       show_prices: prices != [],
       show_custom_fields: custom_field_values != %{},
       show_identification: (item.barcode || item.qr_data) != nil
     )
     |> assign_new(:form, fn ->
       to_form(Inventory.change_item(item))
     end)}
  end

  @impl true
  def handle_event("validate", %{"item" => item_params} = params, socket) do
    changeset = Inventory.change_item(socket.assigns.item, item_params)

    selected_tag_ids =
      (params["tag_ids"] || [])
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.to_integer/1)

    {:noreply,
     assign(socket,
       form: to_form(changeset, action: :validate),
       selected_tag_ids: selected_tag_ids
     )}
  end

  def handle_event("add_price", _params, socket) do
    prices = socket.assigns.prices ++ [%{amount_cents: nil, currency: "EUR", vendor: nil}]
    {:noreply, assign(socket, prices: prices, show_prices: true)}
  end

  def handle_event("remove_price", %{"index" => index}, socket) do
    prices = List.delete_at(socket.assigns.prices, String.to_integer(index))
    {:noreply, assign(socket, prices: prices)}
  end

  def handle_event("toggle_prices", _params, socket) do
    {:noreply, assign(socket, show_prices: !socket.assigns.show_prices)}
  end

  def handle_event("toggle_custom_fields", _params, socket) do
    {:noreply, assign(socket, show_custom_fields: !socket.assigns.show_custom_fields)}
  end

  def handle_event("toggle_identification", _params, socket) do
    {:noreply, assign(socket, show_identification: !socket.assigns.show_identification)}
  end

  def handle_event("save", %{"item" => item_params} = params, socket) do
    tag_ids =
      (params["tag_ids"] || [])
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.to_integer/1)

    save_item(socket, socket.assigns.action, item_params, tag_ids, params)
  end

  defp save_item(socket, :edit, item_params, tag_ids, params) do
    case Inventory.update_item(socket.assigns.item, item_params, tag_ids) do
      {:ok, item} ->
        save_related(item, params)
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item updated")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_item(socket, :new, item_params, tag_ids, params) do
    case Inventory.create_item(socket.assigns.collection, item_params, tag_ids) do
      {:ok, item} ->
        save_related(item, params)
        notify_parent({:saved, item})

        {:noreply,
         socket
         |> put_flash(:info, "Item created")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_related(item, params) do
    if custom_fields = params["custom_fields"] do
      Inventory.set_custom_field_values(item, custom_fields)
    end

    if prices = params["prices"] do
      # Delete existing prices and recreate
      for price <- Inventory.list_item_prices(item) do
        Inventory.delete_item_price(price)
      end

      for {_idx, price_params} <- prices,
          price_params["amount_cents"] != "" and price_params["amount_cents"] != nil do
        Inventory.create_item_price(item, price_params)
      end
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
