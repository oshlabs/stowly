defmodule StowlyWeb.ItemLive.FormComponent do
  use StowlyWeb, :live_component

  alias Stowly.Inventory
  alias Stowly.Inventory.Item
  alias Stowly.Uploads

  @impl true
  def render(assigns) do
    ~H"""
    <div class="px-1">
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
            <option :for={cat <- @categories} value={cat.id}>
              {cat.name}
            </option>
          </.input>

          <.input field={@form[:storage_location_id]} type="select" label="Storage Location">
            <option value="">None</option>
            <option :for={loc <- @storage_locations} value={loc.id}>
              {loc.name} ({loc.location_type})
            </option>
          </.input>

          <div>
            <label class="fieldset-label">Code (barcode / QR)</label>
            <div class="flex gap-2 items-center">
              <input
                type="text"
                name={@form[:code].name}
                value={@form[:code].value}
                class="input input-bordered flex-1"
                placeholder="Scan or enter code"
              />
              <button
                type="button"
                class="btn btn-outline btn-sm"
                phx-click="create_code"
                phx-target={@myself}
              >
                <.icon name="hero-bolt" class="h-4 w-4" /> Create
              </button>
              <button
                type="button"
                class="btn btn-outline btn-sm"
                id="code-scanner-btn"
                phx-hook="CodeScannerHook"
              >
                <.icon name="hero-qr-code" class="h-4 w-4" /> Scan
              </button>
            </div>
          </div>
        </div>

        <%!-- Tags --%>
        <div class="mt-4">
          <label class="fieldset-label">Tags</label>
          <div class="flex flex-wrap gap-3 mt-1">
            <label
              :for={tag <- @tags}
              class="badge gap-1 cursor-pointer select-none"
              style={
                [
                  tag.color && "background-color: #{tag.color}; color: white; border-color: #{tag.color}",
                  if(tag.id in @selected_tag_ids,
                    do: "outline: 2px solid #{tag.color || "currentColor"}; outline-offset: 2px",
                    else: "opacity: 0.5"
                  )
                ]
                |> Enum.filter(& &1)
                |> Enum.join("; ")
              }
            >
              <input
                type="checkbox"
                name="tag_ids[]"
                value={tag.id}
                checked={tag.id in @selected_tag_ids}
                class="hidden"
              />
              {tag.name}
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

        <%!-- Photos - collapsible --%>
        <div class="collapse collapse-arrow bg-base-200 mt-4">
          <input type="checkbox" checked={@show_photos} phx-click="toggle_photos" phx-target={@myself} />
          <div class="collapse-title font-medium">
            Photos ({length(@media) + length(@uploads.photos.entries)})
          </div>
          <div class="collapse-content">
            <div :if={@media != []} class="grid grid-cols-3 gap-2 mb-3">
              <div :for={medium <- @media} class="relative group">
                <img
                  src={Uploads.url(medium.file_path)}
                  alt={medium.original_filename}
                  class="rounded-lg w-full h-24 object-cover"
                />
                <button
                  type="button"
                  class="absolute top-1 right-1 btn btn-circle btn-xs btn-error opacity-0 group-hover:opacity-100 transition-opacity"
                  phx-click="delete_photo"
                  phx-value-id={medium.id}
                  phx-target={@myself}
                  data-confirm="Delete this photo?"
                >
                  <.icon name="hero-x-mark" class="h-3 w-3" />
                </button>
              </div>
            </div>

            <div :for={entry <- @uploads.photos.entries} class="flex items-center gap-2 mb-2">
              <.live_img_preview entry={entry} class="h-12 w-12 rounded object-cover" />
              <span class="text-sm flex-1 truncate">{entry.client_name}</span>
              <progress class="progress progress-primary w-20" value={entry.progress} max="100" />
              <button
                type="button"
                class="btn btn-ghost btn-xs"
                phx-click="cancel_upload"
                phx-value-ref={entry.ref}
                phx-target={@myself}
              >
                <.icon name="hero-x-mark" class="h-3 w-3" />
              </button>
            </div>

            <div :for={err <- upload_errors(@uploads.photos)} class="text-error text-sm mb-1">
              {error_to_string(err)}
            </div>

            <div class="flex gap-2">
              <label class="btn btn-ghost btn-sm">
                <.icon name="hero-arrow-up-tray" class="h-4 w-4" /> Upload
                <.live_file_input upload={@uploads.photos} class="hidden" />
              </label>
              <button
                type="button"
                class="btn btn-ghost btn-sm"
                id="camera-btn"
                phx-hook="CameraHook"
              >
                <.icon name="hero-camera" class="h-4 w-4" /> Camera
              </button>
            </div>
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

    media =
      if item.id && Ecto.assoc_loaded?(item.media) do
        item.media
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
       media: media,
       show_prices: prices != [],
       show_custom_fields: custom_field_values != %{},
       show_photos: media != []
     )
     |> allow_upload(:photos,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 10,
       max_file_size: 20_000_000
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

  def handle_event("create_code", _params, socket) do
    code =
      case socket.assigns.item.id do
        nil -> "code:" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
        id -> "code:#{id}"
      end

    changeset =
      socket.assigns.item
      |> Inventory.change_item(Map.put(socket.assigns.form.params || %{}, "code", code))

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
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

  def handle_event("toggle_photos", _params, socket) do
    {:noreply, assign(socket, show_photos: !socket.assigns.show_photos)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  def handle_event("delete_photo", %{"id" => id}, socket) do
    medium = Inventory.get_medium!(id)
    {:ok, _} = Inventory.delete_medium(medium)

    {:noreply, assign(socket, media: Inventory.list_media(socket.assigns.item))}
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
        save_uploads(socket, item)
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
        save_uploads(socket, item)
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

  defp save_uploads(socket, item) do
    consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
      attrs =
        Uploads.store(
          %{path: path, client_name: entry.client_name, client_type: entry.client_type},
          item.id
        )

      {:ok, _medium} = Inventory.create_medium(item, attrs)
      {:ok, attrs}
    end)
  end

  defp error_to_string(:too_large), do: "File is too large (max 20MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(:too_many_files), do: "Too many files (max 10)"
  defp error_to_string(err), do: "Error: #{inspect(err)}"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
