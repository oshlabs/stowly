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
  Renders a label as an SVG string for the given item or location and template.

  The template's `template` field contains a list of elements, each with:
  - `type`: "text", "field", "barcode", "qr"
  - `field`: the field name (for "field" type) or data source (defaults to "code")
  - `x`, `y`: position in mm
  - `font_size`: font size in pt (for text elements)
  - `width`, `height`: dimensions (for barcode/qr)
  """
  def render_label(%LabelTemplate{} = template, %Stowly.Inventory.Item{} = item) do
    render_label_svg(template, &resolve_item_field(item, &1))
  end

  def render_label(%LabelTemplate{} = template, %Stowly.Inventory.StorageLocation{} = location) do
    render_label_svg(template, &resolve_location_field(location, &1))
  end

  defp render_label_svg(template, resolver) do
    elements = Map.get(template.template, "elements", [])
    width = template.width_mm
    height = template.height_mm

    svg_elements =
      elements
      |> Enum.map(&render_element(&1, resolver))
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n    ")

    """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width}mm" height="#{height}mm" viewBox="0 0 #{width} #{height}">
      <rect width="#{width}" height="#{height}" fill="white" stroke="#ccc" stroke-width="0.1"/>
      #{svg_elements}
    </svg>
    """
  end

  defp render_element(%{"type" => "text", "text" => text} = el, _resolver) do
    x = Map.get(el, "x", 1)
    y = Map.get(el, "y", 5)
    font_size = Map.get(el, "font_size", 3)
    font_weight = Map.get(el, "font_weight", "normal")

    ~s(<text x="#{x}" y="#{y}" font-size="#{font_size}" font-weight="#{font_weight}" font-family="sans-serif">#{escape_svg(text)}</text>)
  end

  defp render_element(%{"type" => "field", "field" => field} = el, resolver) do
    value = resolver.(field)

    if value && value != "" do
      x = Map.get(el, "x", 1)
      y = Map.get(el, "y", 5)
      font_size = Map.get(el, "font_size", 3)
      font_weight = Map.get(el, "font_weight", "normal")

      ~s(<text x="#{x}" y="#{y}" font-size="#{font_size}" font-weight="#{font_weight}" font-family="sans-serif">#{escape_svg(value)}</text>)
    end
  end

  defp render_element(%{"type" => "barcode"} = el, resolver) do
    data = resolver.(Map.get(el, "field", "code"))

    if data && data != "" do
      case Stowly.Codes.generate_barcode_svg(data) do
        {:ok, svg} ->
          x = Map.get(el, "x", 1)
          y = Map.get(el, "y", 10)
          w = Map.get(el, "width", 40)
          h = Map.get(el, "height", 10)

          embed_svg(svg, x, y, w, h)

        _ ->
          nil
      end
    end
  end

  defp render_element(%{"type" => "qr"} = el, resolver) do
    data = resolver.(Map.get(el, "field", "code"))

    if data && data != "" do
      svg = Stowly.Codes.generate_qr_svg(data)

      if svg do
        x = Map.get(el, "x", 1)
        y = Map.get(el, "y", 1)
        w = Map.get(el, "width", 15)
        h = Map.get(el, "height", 15)

        embed_svg(svg, x, y, w, h)
      end
    end
  end

  defp render_element(_, _), do: nil

  # Item field resolution

  defp resolve_item_field(item, "name"), do: item.name
  defp resolve_item_field(item, "description"), do: item.description
  defp resolve_item_field(item, "code"), do: item.code
  defp resolve_item_field(item, "notes"), do: item.notes
  defp resolve_item_field(item, "status"), do: item.status

  defp resolve_item_field(item, "quantity"),
    do: if(item.quantity, do: Integer.to_string(item.quantity))

  defp resolve_item_field(item, "category") do
    case item.category do
      %{name: name} -> name
      _ -> nil
    end
  end

  defp resolve_item_field(item, "location") do
    case item.storage_location do
      %{name: name} -> name
      _ -> nil
    end
  end

  defp resolve_item_field(_, _), do: nil

  # Location field resolution

  defp resolve_location_field(location, "name"), do: location.name
  defp resolve_location_field(location, "description"), do: location.description
  defp resolve_location_field(location, "code"), do: location.code
  defp resolve_location_field(location, "type"), do: location.location_type

  defp resolve_location_field(location, "parent") do
    case location.parent do
      %{name: name} -> name
      _ -> nil
    end
  end

  defp resolve_location_field(_, _), do: nil

  defp embed_svg(svg, x, y, w, h) do
    svg =
      svg
      |> to_string()
      |> String.replace(~r/<\?xml[^?]*\?>/, "")
      |> String.replace(
        ~r/<svg[^>]*viewBox="([^"]*)"[^>]*>/,
        ~s(<svg x="#{x}" y="#{y}" width="#{w}" height="#{h}" viewBox="\\1">)
      )

    svg
  end

  defp escape_svg(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp escape_svg(_), do: ""
end
