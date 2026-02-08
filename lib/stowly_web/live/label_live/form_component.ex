defmodule StowlyWeb.LabelLive.FormComponent do
  use StowlyWeb, :live_component

  alias Stowly.Labels

  @presets [
    {"QR + Text", "qr_text"},
    {"Text + Barcode", "text_barcode"},
    {"Text Only", "text_only"},
    {"QR Only", "qr_only"},
    {"Blank", "blank"}
  ]

  @impl true
  def update(%{template: template} = assigns, socket) do
    changeset = Labels.change_label_template(template)
    layout = Labels.migrate_template_to_v2(template.template || %{})

    preview_template = %{template | template: layout}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:layout, layout)
     |> assign(:preview_svg, Labels.render_label_preview(preview_template))}
  end

  @impl true
  def handle_event("validate", %{"label_template" => template_params} = params, socket) do
    changeset =
      socket.assigns.template
      |> Labels.change_label_template(template_params)
      |> Map.put(:action, :validate)

    target = params |> Map.get("_target", []) |> List.first()
    layout = apply_form_layout_change(socket.assigns.layout, target, params)

    {:noreply,
     socket
     |> assign(changeset: changeset, form: to_form(changeset))
     |> assign(:layout, layout)
     |> update_preview()}
  end

  def handle_event("select_preset", %{"preset" => preset}, socket) do
    layout = Labels.preset_layout(preset)
    {:noreply, socket |> assign(:layout, layout) |> update_preview()}
  end

  def handle_event("add_zone", _params, socket) do
    layout = socket.assigns.layout
    zones = Map.get(layout, "zones", [])

    if length(zones) >= 3 do
      {:noreply, socket}
    else
      new_zone = %{
        "size" => 50,
        "align" => "left",
        "valign" => "top",
        "content" => [
          %{
            "type" => "field",
            "field" => "name",
            "font_size" => "medium",
            "font_weight" => "normal"
          }
        ]
      }

      zones = rebalance_zones(zones ++ [new_zone])
      layout = Map.put(layout, "zones", zones)
      {:noreply, socket |> assign(:layout, layout) |> update_preview()}
    end
  end

  def handle_event("remove_zone", %{"zone" => zone_idx}, socket) do
    zone_idx = String.to_integer(zone_idx)
    layout = socket.assigns.layout
    zones = Map.get(layout, "zones", [])
    zones = List.delete_at(zones, zone_idx)
    zones = rebalance_zones(zones)
    layout = Map.put(layout, "zones", zones)
    {:noreply, socket |> assign(:layout, layout) |> update_preview()}
  end

  def handle_event("add_content", %{"zone" => zone_idx, "type" => type}, socket) do
    zone_idx = String.to_integer(zone_idx)
    layout = socket.assigns.layout
    zones = Map.get(layout, "zones", [])
    zone = Enum.at(zones, zone_idx)

    if zone do
      new_item =
        case type do
          "text" ->
            %{
              "type" => "text",
              "text" => "Label text",
              "font_size" => "medium",
              "font_weight" => "normal"
            }

          _ ->
            %{
              "type" => "field",
              "field" => "name",
              "font_size" => "medium",
              "font_weight" => "normal"
            }
        end

      content = Map.get(zone, "content", []) ++ [new_item]
      zone = Map.put(zone, "content", content)
      zones = List.replace_at(zones, zone_idx, zone)
      layout = Map.put(layout, "zones", zones)
      {:noreply, socket |> assign(:layout, layout) |> update_preview()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_content", %{"zone" => zone_idx, "item" => item_idx}, socket) do
    zone_idx = String.to_integer(zone_idx)
    item_idx = String.to_integer(item_idx)
    layout = socket.assigns.layout
    zones = Map.get(layout, "zones", [])
    zone = Enum.at(zones, zone_idx)

    if zone do
      content = Map.get(zone, "content", []) |> List.delete_at(item_idx)
      zone = Map.put(zone, "content", content)
      zones = List.replace_at(zones, zone_idx, zone)
      layout = Map.put(layout, "zones", zones)
      {:noreply, socket |> assign(:layout, layout) |> update_preview()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_content", %{"zone" => zone_idx, "item" => item_idx} = params, socket) do
    zone_idx = String.to_integer(zone_idx)
    item_idx = String.to_integer(item_idx)
    layout = socket.assigns.layout
    zones = Map.get(layout, "zones", [])
    zone = Enum.at(zones, zone_idx)

    if zone do
      content = Map.get(zone, "content", [])
      item = Enum.at(content, item_idx)

      if item do
        prefix = "content_"
        suffix = "_#{zone_idx}_#{item_idx}"

        item =
          item
          |> maybe_update(params, "font_size")
          |> maybe_update(params, "font_weight")
          |> maybe_update_named(params, prefix, suffix, "field")
          |> maybe_update_named(params, prefix, suffix, "text")

        content = List.replace_at(content, item_idx, item)
        zone = Map.put(zone, "content", content)
        zones = List.replace_at(zones, zone_idx, zone)
        layout = Map.put(layout, "zones", zones)
        {:noreply, socket |> assign(:layout, layout) |> update_preview()}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "move_content",
        %{"zone" => zone_idx, "item" => item_idx, "dir" => dir},
        socket
      ) do
    zone_idx = String.to_integer(zone_idx)
    item_idx = String.to_integer(item_idx)
    layout = socket.assigns.layout
    zones = Map.get(layout, "zones", [])
    zone = Enum.at(zones, zone_idx)

    if zone do
      content = Map.get(zone, "content", [])
      new_idx = if dir == "up", do: item_idx - 1, else: item_idx + 1

      if new_idx >= 0 and new_idx < length(content) do
        item = Enum.at(content, item_idx)
        content = List.delete_at(content, item_idx) |> List.insert_at(new_idx, item)
        zone = Map.put(zone, "content", content)
        zones = List.replace_at(zones, zone_idx, zone)
        layout = Map.put(layout, "zones", zones)
        {:noreply, socket |> assign(:layout, layout) |> update_preview()}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("save", %{"label_template" => params}, socket) do
    params = Map.put(params, "template", socket.assigns.layout)
    save_template(socket, socket.assigns.action, params)
  end

  defp save_template(socket, :new, params) do
    case Labels.create_label_template(socket.assigns.collection, params) do
      {:ok, template} ->
        notify_parent({:saved, template})

        {:noreply,
         socket
         |> put_flash(:info, "Template created")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_template(socket, :edit, params) do
    case Labels.update_label_template(socket.assigns.template, params) do
      {:ok, template} ->
        notify_parent({:saved, template})

        {:noreply,
         socket
         |> put_flash(:info, "Template updated")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp update_preview(socket) do
    changeset = socket.assigns.changeset
    width = Ecto.Changeset.get_field(changeset, :width_mm) || 62
    height = Ecto.Changeset.get_field(changeset, :height_mm) || 29

    preview_template = %Labels.LabelTemplate{
      width_mm: width,
      height_mm: height,
      template: socket.assigns.layout
    }

    assign(socket, :preview_svg, Labels.render_label_preview(preview_template))
  end

  # Process layout changes from form change events based on _target

  defp apply_form_layout_change(layout, "direction", params),
    do: Map.put(layout, "direction", params["direction"])

  defp apply_form_layout_change(layout, "padding", params),
    do: Map.put(layout, "padding", parse_number(params["padding"] || "1.5"))

  defp apply_form_layout_change(layout, "gap", params),
    do: Map.put(layout, "gap", parse_number(params["gap"] || "1.0"))

  defp apply_form_layout_change(layout, target, params) when is_binary(target) do
    zones = Map.get(layout, "zones", [])

    cond do
      match = Regex.run(~r/^zone_code_type_(\d+)$/, target) ->
        [_, idx_str] = match
        idx = String.to_integer(idx_str)

        update_zone_in_layout(layout, zones, idx, fn zone ->
          code_type = params[target]
          content = Map.get(zone, "content", [])

          content =
            case content do
              [item | _] -> [Map.put(item, "type", code_type)]
              _ -> [%{"type" => code_type, "field" => "code"}]
            end

          Map.put(zone, "content", content)
        end)

      match = Regex.run(~r/^zone_(size|align|valign)_(\d+)$/, target) ->
        [_, field, idx_str] = match
        idx = String.to_integer(idx_str)

        update_zone_in_layout(layout, zones, idx, fn zone ->
          value = params[target]
          value = if field == "size", do: parse_int(value), else: value
          Map.put(zone, field, value)
        end)

      match = Regex.run(~r/^content_(field|text)_(\d+)_(\d+)$/, target) ->
        [_, field, z_str, i_str] = match
        z_idx = String.to_integer(z_str)
        i_idx = String.to_integer(i_str)

        update_content_in_layout(layout, zones, z_idx, i_idx, fn item ->
          Map.put(item, field, params[target])
        end)

      true ->
        layout
    end
  end

  defp apply_form_layout_change(layout, _, _), do: layout

  defp update_zone_in_layout(layout, zones, idx, update_fn) do
    case Enum.at(zones, idx) do
      nil -> layout
      zone -> Map.put(layout, "zones", List.replace_at(zones, idx, update_fn.(zone)))
    end
  end

  defp update_content_in_layout(layout, zones, zone_idx, item_idx, update_fn) do
    with zone when not is_nil(zone) <- Enum.at(zones, zone_idx),
         content = Map.get(zone, "content", []),
         item when not is_nil(item) <- Enum.at(content, item_idx) do
      content = List.replace_at(content, item_idx, update_fn.(item))
      zone = Map.put(zone, "content", content)
      Map.put(layout, "zones", List.replace_at(zones, zone_idx, zone))
    else
      _ -> layout
    end
  end

  defp rebalance_zones([]), do: []

  defp rebalance_zones(zones) do
    each = div(100, length(zones))
    remainder = rem(100, length(zones))

    zones
    |> Enum.with_index()
    |> Enum.map(fn {zone, idx} ->
      extra = if idx == 0, do: remainder, else: 0
      Map.put(zone, "size", each + extra)
    end)
  end

  defp maybe_update(map, params, key) do
    case Map.get(params, key) do
      nil -> map
      val -> Map.put(map, key, val)
    end
  end

  defp maybe_update_named(map, params, prefix, suffix, key) do
    case Map.get(params, "#{prefix}#{key}#{suffix}") do
      nil -> map
      val -> Map.put(map, key, val)
    end
  end

  defp parse_number(val) when is_binary(val) do
    case Float.parse(val) do
      {num, ""} -> num
      _ -> val
    end
  end

  defp parse_number(val), do: val

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {num, ""} -> num
      _ -> val
    end
  end

  defp parse_int(val), do: val

  defp zone_type(zone) do
    case Map.get(zone, "content", []) do
      [%{"type" => type} | _] when type in ["qr", "barcode"] -> :code
      _ -> :text
    end
  end

  @item_field_options [
    {"Name", "name"},
    {"Description", "description"},
    {"Category", "category"},
    {"Location", "location"},
    {"Quantity", "quantity"},
    {"Status", "status"},
    {"Code", "code"},
    {"Notes", "notes"}
  ]

  @location_field_options [
    {"Name", "name"},
    {"Description", "description"},
    {"Type", "type"},
    {"Code", "code"},
    {"Parent", "parent"}
  ]

  defp field_options_for("location"), do: @location_field_options
  defp field_options_for(_), do: @item_field_options

  @impl true
  def render(assigns) do
    target_type = Ecto.Changeset.get_field(assigns.changeset, :target_type) || "item"
    assigns = assign(assigns, :field_options, field_options_for(target_type))
    assigns = assign(assigns, :presets, @presets)
    layout = assigns.layout
    zones = Map.get(layout, "zones", [])
    assigns = assign(assigns, :zones, zones)

    ~H"""
    <div>
      <h2 class="text-lg font-bold mb-4">{@title}</h2>

      <.simple_form for={@form} id="template-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Template Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:target_type]} type="select" label="Target Type">
          <option value="item" selected={@form[:target_type].value == "item"}>Item</option>
          <option value="location" selected={@form[:target_type].value == "location"}>Location</option>
        </.input>

        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:width_mm]} type="number" label="Width (mm)" />
          <.input field={@form[:height_mm]} type="number" label="Height (mm)" />
        </div>

        <.input field={@form[:is_default]} type="checkbox" label="Default template" />

        <div class="divider">Layout</div>

        <%!-- Preset selector --%>
        <div class="mb-4">
          <label class="label"><span class="label-text text-xs font-medium">Preset</span></label>
          <div class="flex flex-wrap gap-2">
            <button
              :for={{label, value} <- @presets}
              type="button"
              class="btn btn-outline btn-xs"
              phx-click="select_preset"
              phx-value-preset={value}
              phx-target={@myself}
            >
              {label}
            </button>
          </div>
        </div>

        <%!-- Direction and spacing --%>
        <div class="grid grid-cols-3 gap-3 mb-4">
          <div>
            <label class="label"><span class="label-text text-xs">Direction</span></label>
            <select
              class="select select-bordered select-sm w-full"
              name="direction"
              phx-target={@myself}
            >
              <option value="horizontal" selected={@layout["direction"] == "horizontal"}>Horizontal</option>
              <option value="vertical" selected={@layout["direction"] == "vertical"}>Vertical</option>
            </select>
          </div>
          <div>
            <label class="label"><span class="label-text text-xs">Padding (mm)</span></label>
            <input
              type="number"
              step="0.5"
              min="0"
              value={@layout["padding"]}
              class="input input-bordered input-sm w-full"
              name="padding"
              phx-target={@myself}
            />
          </div>
          <div>
            <label class="label"><span class="label-text text-xs">Gap (mm)</span></label>
            <input
              type="number"
              step="0.5"
              min="0"
              value={@layout["gap"]}
              class="input input-bordered input-sm w-full"
              name="gap"
              phx-target={@myself}
            />
          </div>
        </div>

        <%!-- Zones --%>
        <div class="space-y-3">
          <div
            :for={{zone, zone_idx} <- Enum.with_index(@zones)}
            class="card bg-base-200 card-compact"
          >
            <div class="card-body">
              <div class="flex justify-between items-center">
                <span class="badge badge-sm badge-primary">Zone {zone_idx + 1}</span>
                <button
                  :if={length(@zones) > 1}
                  type="button"
                  class="btn btn-ghost btn-xs text-error"
                  phx-click="remove_zone"
                  phx-value-zone={zone_idx}
                  phx-target={@myself}
                >
                  <.icon name="hero-x-mark" class="h-3 w-3" />
                </button>
              </div>

              <%!-- Zone settings --%>
              <div class="grid grid-cols-3 gap-2 mt-2">
                <div>
                  <label class="label"><span class="label-text text-xs">Size %</span></label>
                  <input
                    type="number"
                    min="10"
                    max="100"
                    value={zone["size"]}
                    class="input input-bordered input-sm w-full"
                    name={"zone_size_#{zone_idx}"}
                  />
                </div>
                <div>
                  <label class="label"><span class="label-text text-xs">Align</span></label>
                  <select
                    class="select select-bordered select-sm w-full"
                    name={"zone_align_#{zone_idx}"}
                  >
                    <option value="left" selected={zone["align"] == "left"}>Left</option>
                    <option value="center" selected={zone["align"] == "center"}>Center</option>
                    <option value="right" selected={zone["align"] == "right"}>Right</option>
                  </select>
                </div>
                <div>
                  <label class="label"><span class="label-text text-xs">V-Align</span></label>
                  <select
                    class="select select-bordered select-sm w-full"
                    name={"zone_valign_#{zone_idx}"}
                  >
                    <option value="top" selected={zone["valign"] == "top"}>Top</option>
                    <option value="middle" selected={zone["valign"] == "middle"}>Middle</option>
                    <option value="bottom" selected={zone["valign"] == "bottom"}>Bottom</option>
                  </select>
                </div>
              </div>

              <%!-- Zone content --%>
              <div :if={zone_type(zone) == :code} class="mt-2">
                <div class="flex items-center gap-2">
                  <label class="label"><span class="label-text text-xs">Code Type</span></label>
                  <select
                    class="select select-bordered select-sm"
                    name={"zone_code_type_#{zone_idx}"}
                  >
                    <option value="qr" selected={hd(zone["content"])["type"] == "qr"}>QR Code</option>
                    <option value="barcode" selected={hd(zone["content"])["type"] == "barcode"}>Barcode</option>
                  </select>
                </div>
              </div>

              <div :if={zone_type(zone) == :text} class="mt-2 space-y-2">
                <div
                  :for={{item, item_idx} <- Enum.with_index(zone["content"] || [])}
                  class="flex items-center gap-1 bg-base-100 rounded px-2 py-1"
                >
                  <%!-- Field select or text input --%>
                  <div :if={item["type"] == "field"} class="flex-1">
                    <select
                      class="select select-bordered select-xs w-full"
                      name={"content_field_#{zone_idx}_#{item_idx}"}
                    >
                      <option
                        :for={{label, value} <- @field_options}
                        value={value}
                        selected={item["field"] == value}
                      >
                        {label}
                      </option>
                    </select>
                  </div>
                  <div :if={item["type"] == "text"} class="flex-1">
                    <input
                      type="text"
                      value={item["text"]}
                      class="input input-bordered input-xs w-full"
                      phx-blur="update_content"
                      phx-value-zone={zone_idx}
                      phx-value-item={item_idx}
                      name={"content_text_#{zone_idx}_#{item_idx}"}
                      phx-target={@myself}
                    />
                  </div>

                  <%!-- Font size buttons --%>
                  <div class="btn-group">
                    <button
                      :for={size <- ["small", "medium", "large"]}
                      type="button"
                      class={"btn btn-xs #{if item["font_size"] == size, do: "btn-active", else: "btn-ghost"}"}
                      phx-click="update_content"
                      phx-value-zone={zone_idx}
                      phx-value-item={item_idx}
                      phx-value-font_size={size}
                      phx-target={@myself}
                    >
                      {String.first(size) |> String.upcase()}
                    </button>
                  </div>

                  <%!-- Bold toggle --%>
                  <button
                    type="button"
                    class={"btn btn-xs #{if item["font_weight"] == "bold", do: "btn-active", else: "btn-ghost"}"}
                    phx-click="update_content"
                    phx-value-zone={zone_idx}
                    phx-value-item={item_idx}
                    phx-value-font_weight={if item["font_weight"] == "bold", do: "normal", else: "bold"}
                    phx-target={@myself}
                  >
                    B
                  </button>

                  <%!-- Move up/down --%>
                  <button
                    type="button"
                    class="btn btn-ghost btn-xs"
                    phx-click="move_content"
                    phx-value-zone={zone_idx}
                    phx-value-item={item_idx}
                    phx-value-dir="up"
                    phx-target={@myself}
                    disabled={item_idx == 0}
                  >
                    <.icon name="hero-chevron-up" class="h-3 w-3" />
                  </button>
                  <button
                    type="button"
                    class="btn btn-ghost btn-xs"
                    phx-click="move_content"
                    phx-value-zone={zone_idx}
                    phx-value-item={item_idx}
                    phx-value-dir="down"
                    phx-target={@myself}
                    disabled={item_idx == length(zone["content"] || []) - 1}
                  >
                    <.icon name="hero-chevron-down" class="h-3 w-3" />
                  </button>

                  <%!-- Remove --%>
                  <button
                    type="button"
                    class="btn btn-ghost btn-xs text-error"
                    phx-click="remove_content"
                    phx-value-zone={zone_idx}
                    phx-value-item={item_idx}
                    phx-target={@myself}
                  >
                    <.icon name="hero-x-mark" class="h-3 w-3" />
                  </button>
                </div>

                <div class="flex gap-1">
                  <button
                    type="button"
                    class="btn btn-outline btn-xs"
                    phx-click="add_content"
                    phx-value-zone={zone_idx}
                    phx-value-type="field"
                    phx-target={@myself}
                  >
                    + Field
                  </button>
                  <button
                    type="button"
                    class="btn btn-outline btn-xs"
                    phx-click="add_content"
                    phx-value-zone={zone_idx}
                    phx-value-type="text"
                    phx-target={@myself}
                  >
                    + Text
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div :if={length(@zones) < 3} class="mt-2">
          <button
            type="button"
            class="btn btn-outline btn-sm"
            phx-click="add_zone"
            phx-target={@myself}
          >
            + Add Zone
          </button>
        </div>

        <%!-- Live preview --%>
        <div class="divider">Preview</div>
        <div class="flex justify-center p-4 bg-base-200 rounded-lg">
          {Phoenix.HTML.raw(@preview_svg)}
        </div>

        <:actions>
          <button type="submit" class="btn btn-primary">Save Template</button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
