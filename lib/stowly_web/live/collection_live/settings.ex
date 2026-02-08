defmodule StowlyWeb.CollectionLive.Settings do
  use StowlyWeb, :live_view

  alias Stowly.Inventory
  alias Stowly.Inventory.Category
  alias Stowly.Inventory.Tag
  alias Stowly.Inventory.CustomFieldDefinition

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    collection = Inventory.get_collection!(id)

    {:ok,
     socket
     |> assign(
       collection: collection,
       page_title: "#{collection.name} Settings",
       active_tab: "categories",
       categories: Inventory.list_categories(collection),
       tags: Inventory.list_tags(collection),
       field_definitions: Inventory.list_custom_field_definitions(collection),
       editing: nil,
       category_form: to_form(Inventory.change_category(%Category{})),
       tag_form: to_form(Inventory.change_tag(%Tag{})),
       field_def_form:
         to_form(Inventory.change_custom_field_definition(%CustomFieldDefinition{})),
       theme_form: to_form(theme_to_params(collection.theme))
     )}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _url, socket) when tab in ~w(categories tags fields theme) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/collections/#{socket.assigns.collection}/settings?tab=#{tab}")}
  end

  def handle_event("validate_category", %{"category" => params}, socket) do
    changeset =
      (socket.assigns.editing || %Category{})
      |> Inventory.change_category(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, category_form: to_form(changeset))}
  end

  def handle_event("save_category", %{"category" => params}, socket) do
    collection = socket.assigns.collection

    result =
      if socket.assigns.editing do
        Inventory.update_category(socket.assigns.editing, params)
      else
        Inventory.create_category(collection, params)
      end

    case result do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category saved")
         |> assign(
           categories: Inventory.list_categories(collection),
           editing: nil,
           category_form: to_form(Inventory.change_category(%Category{}))
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, category_form: to_form(changeset))}
    end
  end

  def handle_event("edit_category", %{"id" => id}, socket) do
    category = Inventory.get_category!(id)

    {:noreply,
     assign(socket,
       editing: category,
       category_form: to_form(Inventory.change_category(category))
     )}
  end

  def handle_event("delete_category", %{"id" => id}, socket) do
    category = Inventory.get_category!(id)
    {:ok, _} = Inventory.delete_category(category)

    {:noreply,
     socket
     |> put_flash(:info, "Category deleted")
     |> assign(categories: Inventory.list_categories(socket.assigns.collection))}
  end

  def handle_event("validate_tag", %{"tag" => params}, socket) do
    changeset =
      (socket.assigns.editing || %Tag{})
      |> Inventory.change_tag(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, tag_form: to_form(changeset))}
  end

  def handle_event("save_tag", %{"tag" => params}, socket) do
    collection = socket.assigns.collection

    result =
      if socket.assigns.editing do
        Inventory.update_tag(socket.assigns.editing, params)
      else
        Inventory.create_tag(collection, params)
      end

    case result do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag saved")
         |> assign(
           tags: Inventory.list_tags(collection),
           editing: nil,
           tag_form: to_form(Inventory.change_tag(%Tag{}))
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, tag_form: to_form(changeset))}
    end
  end

  def handle_event("edit_tag", %{"id" => id}, socket) do
    tag = Inventory.get_tag!(id)

    {:noreply,
     assign(socket,
       editing: tag,
       tag_form: to_form(Inventory.change_tag(tag))
     )}
  end

  def handle_event("delete_tag", %{"id" => id}, socket) do
    tag = Inventory.get_tag!(id)
    {:ok, _} = Inventory.delete_tag(tag)

    {:noreply,
     socket
     |> put_flash(:info, "Tag deleted")
     |> assign(tags: Inventory.list_tags(socket.assigns.collection))}
  end

  def handle_event("validate_field_def", %{"custom_field_definition" => params}, socket) do
    changeset =
      (socket.assigns.editing || %CustomFieldDefinition{})
      |> Inventory.change_custom_field_definition(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, field_def_form: to_form(changeset))}
  end

  def handle_event("save_field_def", %{"custom_field_definition" => params}, socket) do
    collection = socket.assigns.collection

    result =
      if socket.assigns.editing do
        Inventory.update_custom_field_definition(socket.assigns.editing, params)
      else
        Inventory.create_custom_field_definition(collection, params)
      end

    case result do
      {:ok, _field_def} ->
        {:noreply,
         socket
         |> put_flash(:info, "Custom field saved")
         |> assign(
           field_definitions: Inventory.list_custom_field_definitions(collection),
           editing: nil,
           field_def_form:
             to_form(Inventory.change_custom_field_definition(%CustomFieldDefinition{}))
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, field_def_form: to_form(changeset))}
    end
  end

  def handle_event("edit_field_def", %{"id" => id}, socket) do
    field_def = Inventory.get_custom_field_definition!(id)

    {:noreply,
     assign(socket,
       editing: field_def,
       field_def_form: to_form(Inventory.change_custom_field_definition(field_def))
     )}
  end

  def handle_event("delete_field_def", %{"id" => id}, socket) do
    field_def = Inventory.get_custom_field_definition!(id)
    {:ok, _} = Inventory.delete_custom_field_definition(field_def)

    {:noreply,
     socket
     |> put_flash(:info, "Custom field deleted")
     |> assign(
       field_definitions: Inventory.list_custom_field_definitions(socket.assigns.collection)
     )}
  end

  def handle_event("validate_theme", %{"theme" => params}, socket) do
    {:noreply, assign(socket, theme_form: to_form(params, as: :theme))}
  end

  def handle_event("save_theme", %{"theme" => params}, socket) do
    collection = socket.assigns.collection
    theme = build_theme(params)

    case Inventory.update_collection(collection, %{theme: theme}) do
      {:ok, collection} ->
        {:noreply,
         socket
         |> put_flash(:info, "Theme updated")
         |> assign(collection: collection, theme_form: to_form(theme_to_params(collection.theme)))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update theme")}
    end
  end

  def handle_event("reset_theme", _params, socket) do
    collection = socket.assigns.collection

    case Inventory.update_collection(collection, %{theme: %{}}) do
      {:ok, collection} ->
        {:noreply,
         socket
         |> put_flash(:info, "Theme reset to default")
         |> assign(collection: collection, theme_form: to_form(theme_to_params(%{})))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reset theme")}
    end
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     assign(socket,
       editing: nil,
       category_form: to_form(Inventory.change_category(%Category{})),
       tag_form: to_form(Inventory.change_tag(%Tag{})),
       field_def_form: to_form(Inventory.change_custom_field_definition(%CustomFieldDefinition{}))
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.theme_applicator theme={@collection.theme} />
    <.back navigate={~p"/collections/#{@collection}"}>
      {@collection.name}
    </.back>

    <.header>
      Settings
      <:subtitle>Manage categories, tags, custom fields, and theme for {@collection.name}</:subtitle>
    </.header>

    <div role="tablist" class="tabs tabs-bordered mt-6">
      <button
        role="tab"
        class={["tab", @active_tab == "categories" && "tab-active"]}
        phx-click="switch_tab"
        phx-value-tab="categories"
      >
        Categories
      </button>
      <button
        role="tab"
        class={["tab", @active_tab == "tags" && "tab-active"]}
        phx-click="switch_tab"
        phx-value-tab="tags"
      >
        Tags
      </button>
      <button
        role="tab"
        class={["tab", @active_tab == "fields" && "tab-active"]}
        phx-click="switch_tab"
        phx-value-tab="fields"
      >
        Custom Fields
      </button>
      <button
        role="tab"
        class={["tab", @active_tab == "theme" && "tab-active"]}
        phx-click="switch_tab"
        phx-value-tab="theme"
      >
        Theme
      </button>
    </div>

    <div class="mt-6">
      <div :if={@active_tab == "categories"}>
        <.categories_panel
          categories={@categories}
          form={@category_form}
          editing={@editing}
          collection={@collection}
        />
      </div>
      <div :if={@active_tab == "tags"}>
        <.tags_panel tags={@tags} form={@tag_form} editing={@editing} />
      </div>
      <div :if={@active_tab == "fields"}>
        <.fields_panel
          field_definitions={@field_definitions}
          form={@field_def_form}
          editing={@editing}
        />
      </div>
      <div :if={@active_tab == "theme"}>
        <.theme_panel collection={@collection} theme_form={@theme_form} />
      </div>
    </div>
    """
  end

  defp categories_panel(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div>
        <h3 class="font-bold mb-4">{if @editing, do: "Edit Category", else: "New Category"}</h3>
        <.simple_form for={@form} phx-change="validate_category" phx-submit="save_category">
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:description]} type="text" label="Description" />
          <.input field={@form[:color]} type="text" label="Color" placeholder="#3b82f6" />
          <.input
            field={@form[:parent_id]}
            type="select"
            label="Parent Category"
          >
            <option value="">None (top-level)</option>
            <option
              :for={cat <- @categories}
              value={cat.id}
              selected={Phoenix.HTML.Form.normalize_value("select", @form[:parent_id].value) == to_string(cat.id)}
            >
              {cat.name}
            </option>
          </.input>
          <:actions>
            <.button type="submit" class="btn-primary">Save Category</.button>
            <.button :if={@editing} type="button" class="btn-ghost" phx-click="cancel_edit">
              Cancel
            </.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <h3 class="font-bold mb-4">Categories</h3>
        <div :if={@categories == []} class="text-base-content/50">No categories yet</div>
        <div :for={category <- @categories} class="flex items-center justify-between py-2 border-b border-base-300">
          <div class="flex items-center gap-2">
            <span
              :if={category.color}
              class="w-3 h-3 rounded-full inline-block"
              style={"background-color: #{category.color}"}
            />
            <span>{category.name}</span>
            <span :if={category.parent_id} class="badge badge-ghost badge-sm">sub</span>
          </div>
          <div class="flex gap-1">
            <button class="btn btn-ghost btn-xs" phx-click="edit_category" phx-value-id={category.id}>
              <.icon name="hero-pencil-square" class="h-3 w-3" />
            </button>
            <button
              class="btn btn-ghost btn-xs text-error"
              phx-click="delete_category"
              phx-value-id={category.id}
              data-confirm="Delete this category?"
            >
              <.icon name="hero-trash" class="h-3 w-3" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp tags_panel(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div>
        <h3 class="font-bold mb-4">{if @editing, do: "Edit Tag", else: "New Tag"}</h3>
        <.simple_form for={@form} phx-change="validate_tag" phx-submit="save_tag">
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:color]} type="text" label="Color" placeholder="#3b82f6" />
          <:actions>
            <.button type="submit" class="btn-primary">Save Tag</.button>
            <.button :if={@editing} type="button" class="btn-ghost" phx-click="cancel_edit">
              Cancel
            </.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <h3 class="font-bold mb-4">Tags</h3>
        <div :if={@tags == []} class="text-base-content/50">No tags yet</div>
        <div class="flex flex-wrap gap-2">
          <div :for={tag <- @tags} class="badge badge-lg gap-2">
            <span
              :if={tag.color}
              class="w-2 h-2 rounded-full inline-block"
              style={"background-color: #{tag.color}"}
            />
            {tag.name}
            <button class="btn btn-ghost btn-xs p-0" phx-click="edit_tag" phx-value-id={tag.id}>
              <.icon name="hero-pencil-square" class="h-3 w-3" />
            </button>
            <button
              class="btn btn-ghost btn-xs p-0 text-error"
              phx-click="delete_tag"
              phx-value-id={tag.id}
              data-confirm="Delete this tag?"
            >
              <.icon name="hero-x-mark" class="h-3 w-3" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp fields_panel(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div>
        <h3 class="font-bold mb-4">
          {if @editing, do: "Edit Custom Field", else: "New Custom Field"}
        </h3>
        <.simple_form for={@form} phx-change="validate_field_def" phx-submit="save_field_def">
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:field_type]} type="select" label="Type">
            <option :for={t <- CustomFieldDefinition.field_types()} value={t}>
              {String.capitalize(String.replace(t, "_", " "))}
            </option>
          </.input>
          <.input field={@form[:required]} type="checkbox" label="Required" />
          <:actions>
            <.button type="submit" class="btn-primary">Save Field</.button>
            <.button :if={@editing} type="button" class="btn-ghost" phx-click="cancel_edit">
              Cancel
            </.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <h3 class="font-bold mb-4">Custom Fields</h3>
        <div :if={@field_definitions == []} class="text-base-content/50">
          No custom fields yet
        </div>
        <div
          :for={fd <- @field_definitions}
          class="flex items-center justify-between py-2 border-b border-base-300"
        >
          <div>
            <span class="font-medium">{fd.name}</span>
            <span class="badge badge-ghost badge-sm ml-2">{fd.field_type}</span>
            <span :if={fd.required} class="badge badge-warning badge-sm ml-1">required</span>
          </div>
          <div class="flex gap-1">
            <button
              class="btn btn-ghost btn-xs"
              phx-click="edit_field_def"
              phx-value-id={fd.id}
            >
              <.icon name="hero-pencil-square" class="h-3 w-3" />
            </button>
            <button
              class="btn btn-ghost btn-xs text-error"
              phx-click="delete_field_def"
              phx-value-id={fd.id}
              data-confirm="Delete this custom field?"
            >
              <.icon name="hero-trash" class="h-3 w-3" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @base_themes [
    {"Default (Light)", "light"},
    {"Dark", "dark"}
  ]

  defp theme_panel(assigns) do
    assigns = assign(assigns, :base_themes, @base_themes)

    ~H"""
    <div class="max-w-2xl">
      <h3 class="font-bold mb-4">Collection Theme</h3>
      <p class="text-sm text-base-content/70 mb-4">
        Customize the visual appearance of this collection. Colors use
        <a href="https://oklch.com" target="_blank" class="link">OKLCH format</a>
        (e.g., "oklch(70% 0.213 47.604)").
      </p>

      <.simple_form for={@theme_form} phx-change="validate_theme" phx-submit="save_theme">
        <.input field={@theme_form[:base_theme]} type="select" label="Base Theme">
          <option value="">Default</option>
          <option
            :for={{label, value} <- @base_themes}
            value={value}
            selected={Phoenix.HTML.Form.normalize_value("select", @theme_form[:base_theme].value) == value}
          >
            {label}
          </option>
        </.input>

        <div class="divider text-sm">Color Overrides (optional)</div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@theme_form[:primary]} type="text" label="Primary" placeholder="oklch(70% 0.213 47.604)" />
          <.input field={@theme_form[:primary_content]} type="text" label="Primary Content" placeholder="oklch(98% 0.016 73.684)" />
          <.input field={@theme_form[:secondary]} type="text" label="Secondary" placeholder="oklch(55% 0.027 264.364)" />
          <.input field={@theme_form[:secondary_content]} type="text" label="Secondary Content" placeholder="oklch(98% 0.002 247.839)" />
          <.input field={@theme_form[:accent]} type="text" label="Accent" placeholder="oklch(60% 0.25 292.717)" />
          <.input field={@theme_form[:accent_content]} type="text" label="Accent Content" placeholder="oklch(96% 0.016 293.756)" />
          <.input field={@theme_form[:neutral]} type="text" label="Neutral" placeholder="oklch(44% 0.017 285.786)" />
          <.input field={@theme_form[:neutral_content]} type="text" label="Neutral Content" placeholder="oklch(98% 0 0)" />
          <.input field={@theme_form[:base_100]} type="text" label="Base 100" placeholder="oklch(98% 0 0)" />
          <.input field={@theme_form[:base_200]} type="text" label="Base 200" placeholder="oklch(96% 0.001 286.375)" />
          <.input field={@theme_form[:base_300]} type="text" label="Base 300" placeholder="oklch(92% 0.004 286.32)" />
          <.input field={@theme_form[:base_content]} type="text" label="Base Content" placeholder="oklch(21% 0.006 285.885)" />
        </div>

        <:actions>
          <.button type="submit" class="btn-primary">Save Theme</.button>
          <.button type="button" class="btn-ghost" phx-click="reset_theme">Reset to Default</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @theme_keys ~w(base_theme primary primary_content secondary secondary_content accent accent_content neutral neutral_content base_100 base_200 base_300 base_content)

  defp theme_to_params(nil), do: %{}

  defp theme_to_params(theme) when is_map(theme) do
    Map.take(theme, @theme_keys)
  end

  defp build_theme(params) do
    params
    |> Map.take(@theme_keys)
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
    |> Map.new()
  end
end
