defmodule Stowly.Labels do
  @moduledoc """
  Label template management and rendering.
  """
  import Ecto.Query
  alias Stowly.Repo
  alias Stowly.Labels.LabelTemplate
  alias Stowly.Inventory.Collection

  ## Templates

  def list_label_templates(%Collection{} = collection) do
    LabelTemplate
    |> where(collection_id: ^collection.id)
    |> order_by(asc: :name)
    |> Repo.all()
  end

  def list_global_label_templates do
    LabelTemplate
    |> where([t], is_nil(t.collection_id))
    |> order_by(asc: :name)
    |> Repo.all()
  end

  def get_label_template!(id), do: Repo.get!(LabelTemplate, id)

  def create_label_template(attrs) do
    %LabelTemplate{}
    |> LabelTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def create_label_template(%Collection{} = collection, attrs) do
    %LabelTemplate{collection_id: collection.id}
    |> LabelTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def update_label_template(%LabelTemplate{} = template, attrs) do
    template
    |> LabelTemplate.changeset(attrs)
    |> Repo.update()
  end

  def delete_label_template(%LabelTemplate{} = template) do
    Repo.delete(template)
  end

  def change_label_template(%LabelTemplate{} = template, attrs \\ %{}) do
    LabelTemplate.changeset(template, attrs)
  end

  ## Rendering

  @doc """
  Renders a label as an SVG string for the given item and template.

  The template's `template` field contains a list of elements, each with:
  - `type`: "text", "field", "barcode", "qr"
  - `field`: the item field name (for "field" type) or data source
  - `x`, `y`: position in mm
  - `font_size`: font size in pt (for text elements)
  - `width`, `height`: dimensions (for barcode/qr)
  """
  def render_label(%LabelTemplate{} = template, %Stowly.Inventory.Item{} = item) do
    elements = Map.get(template.template, "elements", [])
    width = template.width_mm
    height = template.height_mm

    svg_elements =
      elements
      |> Enum.map(&render_element(&1, item))
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n    ")

    """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width}mm" height="#{height}mm" viewBox="0 0 #{width} #{height}">
      <rect width="#{width}" height="#{height}" fill="white" stroke="#ccc" stroke-width="0.1"/>
      #{svg_elements}
    </svg>
    """
  end

  defp render_element(%{"type" => "text", "text" => text} = el, _item) do
    x = Map.get(el, "x", 1)
    y = Map.get(el, "y", 5)
    font_size = Map.get(el, "font_size", 3)
    font_weight = Map.get(el, "font_weight", "normal")

    ~s(<text x="#{x}" y="#{y}" font-size="#{font_size}" font-weight="#{font_weight}" font-family="sans-serif">#{escape_svg(text)}</text>)
  end

  defp render_element(%{"type" => "field", "field" => field} = el, item) do
    value = resolve_field(item, field)

    if value && value != "" do
      x = Map.get(el, "x", 1)
      y = Map.get(el, "y", 5)
      font_size = Map.get(el, "font_size", 3)
      font_weight = Map.get(el, "font_weight", "normal")

      ~s(<text x="#{x}" y="#{y}" font-size="#{font_size}" font-weight="#{font_weight}" font-family="sans-serif">#{escape_svg(value)}</text>)
    end
  end

  defp render_element(%{"type" => "barcode"} = el, item) do
    data = resolve_field(item, Map.get(el, "field", "barcode"))

    if data && data != "" do
      case Stowly.Codes.generate_barcode_svg(data) do
        {:ok, svg} ->
          x = Map.get(el, "x", 1)
          y = Map.get(el, "y", 10)
          w = Map.get(el, "width", 40)
          h = Map.get(el, "height", 10)

          ~s(<foreignObject x="#{x}" y="#{y}" width="#{w}" height="#{h}">#{svg}</foreignObject>)

        _ ->
          nil
      end
    end
  end

  defp render_element(%{"type" => "qr"} = el, item) do
    data = resolve_field(item, Map.get(el, "field", "qr_data"))

    if data && data != "" do
      svg = Stowly.Codes.generate_qr_svg(data)

      if svg do
        x = Map.get(el, "x", 1)
        y = Map.get(el, "y", 1)
        w = Map.get(el, "width", 15)
        h = Map.get(el, "height", 15)

        ~s(<foreignObject x="#{x}" y="#{y}" width="#{w}" height="#{h}">#{svg}</foreignObject>)
      end
    end
  end

  defp render_element(_, _), do: nil

  defp resolve_field(item, "name"), do: item.name
  defp resolve_field(item, "description"), do: item.description
  defp resolve_field(item, "barcode"), do: item.barcode
  defp resolve_field(item, "qr_data"), do: item.qr_data
  defp resolve_field(item, "notes"), do: item.notes
  defp resolve_field(item, "status"), do: item.status

  defp resolve_field(item, "quantity"),
    do: if(item.quantity, do: Integer.to_string(item.quantity))

  defp resolve_field(item, "category") do
    case item.category do
      %{name: name} -> name
      _ -> nil
    end
  end

  defp resolve_field(item, "location") do
    case item.storage_location do
      %{name: name} -> name
      _ -> nil
    end
  end

  defp resolve_field(_, _), do: nil

  defp escape_svg(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp escape_svg(_), do: ""
end
