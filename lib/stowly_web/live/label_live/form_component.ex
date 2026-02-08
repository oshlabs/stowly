defmodule StowlyWeb.LabelLive.FormComponent do
  use StowlyWeb, :live_component

  alias Stowly.Labels

  @impl true
  def update(%{template: template} = assigns, socket) do
    changeset = Labels.change_label_template(template)

    elements = Map.get(template.template, "elements", [])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:elements, elements)}
  end

  @impl true
  def handle_event("validate", %{"label_template" => params}, socket) do
    changeset =
      socket.assigns.template
      |> Labels.change_label_template(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
  end

  def handle_event("add_element", %{"type" => type}, socket) do
    new_element = default_element(type)
    elements = socket.assigns.elements ++ [new_element]
    {:noreply, assign(socket, elements: elements)}
  end

  def handle_event("remove_element", %{"index" => index}, socket) do
    index = String.to_integer(index)
    elements = List.delete_at(socket.assigns.elements, index)
    {:noreply, assign(socket, elements: elements)}
  end

  def handle_event("update_element", %{"index" => index} = params, socket) do
    index = String.to_integer(index)
    element = Enum.at(socket.assigns.elements, index) || %{}

    updated =
      element
      |> maybe_put(params, "x")
      |> maybe_put(params, "y")
      |> maybe_put(params, "font_size")
      |> maybe_put(params, "font_weight")
      |> maybe_put(params, "text")
      |> maybe_put(params, "field")
      |> maybe_put(params, "width")
      |> maybe_put(params, "height")

    elements = List.replace_at(socket.assigns.elements, index, updated)
    {:noreply, assign(socket, elements: elements)}
  end

  def handle_event("save", %{"label_template" => params}, socket) do
    params = Map.put(params, "template", %{"elements" => socket.assigns.elements})
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

  defp default_element("text") do
    %{
      "type" => "text",
      "text" => "Label text",
      "x" => 1,
      "y" => 5,
      "font_size" => 3,
      "font_weight" => "normal"
    }
  end

  defp default_element("field") do
    %{
      "type" => "field",
      "field" => "name",
      "x" => 1,
      "y" => 5,
      "font_size" => 3,
      "font_weight" => "bold"
    }
  end

  defp default_element("barcode") do
    %{
      "type" => "barcode",
      "field" => "code",
      "x" => 1,
      "y" => 15,
      "width" => 40,
      "height" => 10
    }
  end

  defp default_element("qr") do
    %{"type" => "qr", "field" => "code", "x" => 1, "y" => 1, "width" => 15, "height" => 15}
  end

  defp default_element(_), do: %{"type" => "text", "text" => "", "x" => 0, "y" => 0}

  defp maybe_put(element, params, key) do
    case Map.get(params, key) do
      nil -> element
      "" -> element
      val -> Map.put(element, key, parse_number(val))
    end
  end

  defp parse_number(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, ""} ->
        int

      _ ->
        case Float.parse(val) do
          {float, ""} -> float
          _ -> val
        end
    end
  end

  defp parse_number(val), do: val

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

        <div class="divider">Label Elements</div>

        <div class="space-y-3">
          <div
            :for={{element, index} <- Enum.with_index(@elements)}
            class="card bg-base-200 card-compact"
          >
            <div class="card-body">
              <div class="flex justify-between items-center">
                <span class="badge badge-sm">{element["type"]}</span>
                <button
                  type="button"
                  class="btn btn-ghost btn-xs text-error"
                  phx-click="remove_element"
                  phx-value-index={index}
                  phx-target={@myself}
                >
                  <.icon name="hero-x-mark" class="h-3 w-3" />
                </button>
              </div>

              <div :if={element["type"] == "text"} class="mt-2">
                <label class="label"><span class="label-text text-xs">Text</span></label>
                <input
                  type="text"
                  value={element["text"]}
                  class="input input-bordered input-sm w-full"
                  phx-blur="update_element"
                  phx-value-index={index}
                  phx-value-text={element["text"]}
                  name={"element_text_#{index}"}
                  phx-target={@myself}
                />
              </div>

              <div :if={element["type"] in ["field", "barcode", "qr"]} class="mt-2">
                <label class="label"><span class="label-text text-xs">Field</span></label>
                <select
                  class="select select-bordered select-sm w-full"
                  phx-change="update_element"
                  phx-value-index={index}
                  name={"element_field_#{index}"}
                  phx-target={@myself}
                >
                  <option
                    :for={{label, value} <- @field_options}
                    value={value}
                    selected={element["field"] == value}
                  >
                    {label}
                  </option>
                </select>
              </div>

              <div class="grid grid-cols-2 gap-2 mt-2">
                <div>
                  <label class="label"><span class="label-text text-xs">X (mm)</span></label>
                  <input
                    type="number"
                    value={element["x"]}
                    class="input input-bordered input-sm w-full"
                    phx-blur="update_element"
                    phx-value-index={index}
                    name={"element_x_#{index}"}
                    phx-target={@myself}
                  />
                </div>
                <div>
                  <label class="label"><span class="label-text text-xs">Y (mm)</span></label>
                  <input
                    type="number"
                    value={element["y"]}
                    class="input input-bordered input-sm w-full"
                    phx-blur="update_element"
                    phx-value-index={index}
                    name={"element_y_#{index}"}
                    phx-target={@myself}
                  />
                </div>
              </div>

              <div :if={element["type"] in ["text", "field"]} class="grid grid-cols-2 gap-2 mt-1">
                <div>
                  <label class="label"><span class="label-text text-xs">Font Size</span></label>
                  <input
                    type="number"
                    value={element["font_size"]}
                    class="input input-bordered input-sm w-full"
                    phx-blur="update_element"
                    phx-value-index={index}
                    name={"element_font_size_#{index}"}
                    phx-target={@myself}
                  />
                </div>
                <div>
                  <label class="label"><span class="label-text text-xs">Weight</span></label>
                  <select
                    class="select select-bordered select-sm w-full"
                    phx-change="update_element"
                    phx-value-index={index}
                    name={"element_font_weight_#{index}"}
                    phx-target={@myself}
                  >
                    <option value="normal" selected={element["font_weight"] == "normal"}>Normal</option>
                    <option value="bold" selected={element["font_weight"] == "bold"}>Bold</option>
                  </select>
                </div>
              </div>

              <div :if={element["type"] in ["barcode", "qr"]} class="grid grid-cols-2 gap-2 mt-1">
                <div>
                  <label class="label"><span class="label-text text-xs">Width</span></label>
                  <input
                    type="number"
                    value={element["width"]}
                    class="input input-bordered input-sm w-full"
                    phx-blur="update_element"
                    phx-value-index={index}
                    name={"element_width_#{index}"}
                    phx-target={@myself}
                  />
                </div>
                <div>
                  <label class="label"><span class="label-text text-xs">Height</span></label>
                  <input
                    type="number"
                    value={element["height"]}
                    class="input input-bordered input-sm w-full"
                    phx-blur="update_element"
                    phx-value-index={index}
                    name={"element_height_#{index}"}
                    phx-target={@myself}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="flex gap-2 mt-2">
          <button type="button" class="btn btn-outline btn-xs" phx-click="add_element" phx-value-type="field" phx-target={@myself}>
            + Field
          </button>
          <button type="button" class="btn btn-outline btn-xs" phx-click="add_element" phx-value-type="text" phx-target={@myself}>
            + Text
          </button>
          <button type="button" class="btn btn-outline btn-xs" phx-click="add_element" phx-value-type="barcode" phx-target={@myself}>
            + Barcode
          </button>
          <button type="button" class="btn btn-outline btn-xs" phx-click="add_element" phx-value-type="qr" phx-target={@myself}>
            + QR Code
          </button>
        </div>

        <:actions>
          <button type="submit" class="btn btn-primary">Save Template</button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
