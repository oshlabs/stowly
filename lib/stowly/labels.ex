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
  Dispatches to v2 zone layout or v1 legacy elements based on template version.
  """
  def render_label(%LabelTemplate{} = template, %Stowly.Inventory.Item{} = item) do
    render_label_svg(template, &resolve_item_field(item, &1))
  end

  def render_label(%LabelTemplate{} = template, %Stowly.Inventory.StorageLocation{} = location) do
    render_label_svg(template, &resolve_location_field(location, &1))
  end

  @doc """
  Renders a label preview with placeholder data (no real item/location needed).
  """
  def render_label_preview(%LabelTemplate{} = template) do
    resolver = &preview_field_value/1
    render_label_svg(template, resolver)
  end

  defp preview_field_value("name"), do: "Sample Name"
  defp preview_field_value("description"), do: "Description text"
  defp preview_field_value("code"), do: "STW-001"
  defp preview_field_value("category"), do: "Category"
  defp preview_field_value("location"), do: "Shelf A1"
  defp preview_field_value("quantity"), do: "5"
  defp preview_field_value("status"), do: "available"
  defp preview_field_value("notes"), do: "Some notes"
  defp preview_field_value("type"), do: "shelf"
  defp preview_field_value("parent"), do: "Warehouse"
  defp preview_field_value(_), do: "Value"

  defp render_label_svg(template, resolver) do
    width = template.width_mm
    height = template.height_mm

    svg_elements =
      case Map.get(template.template, "version") do
        2 -> render_zone_layout(template.template, width, height, resolver)
        _ -> render_v1_elements(template.template, resolver)
      end

    """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width}mm" height="#{height}mm" viewBox="0 0 #{width} #{height}">
      <rect width="#{width}" height="#{height}" fill="white" stroke="#ccc" stroke-width="0.1"/>
      #{svg_elements}
    </svg>
    """
  end

  # V1 legacy rendering

  defp render_v1_elements(template_map, resolver) do
    template_map
    |> Map.get("elements", [])
    |> Enum.map(&render_element(&1, resolver))
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n    ")
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

  # V2 zone layout rendering

  defp render_zone_layout(layout, width, height, resolver) do
    padding = Map.get(layout, "padding", 1.5)
    gap = Map.get(layout, "gap", 1.0)
    direction = Map.get(layout, "direction", "horizontal")
    zones = Map.get(layout, "zones", [])

    boxes = compute_zone_boxes(zones, direction, padding, gap, width, height)

    boxes
    |> Enum.map(fn {zone, box} -> render_zone_content(zone, box, resolver, height) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n    ")
  end

  defp compute_zone_boxes(zones, direction, padding, gap, width, height) do
    inner_w = width - padding * 2
    inner_h = height - padding * 2
    total_gap = gap * max(length(zones) - 1, 0)

    {available, _} =
      case direction do
        "vertical" -> {inner_h - total_gap, inner_w}
        _ -> {inner_w - total_gap, inner_h}
      end

    {boxes, _offset} =
      Enum.reduce(zones, {[], 0}, fn zone, {acc, offset} ->
        size_pct = Map.get(zone, "size", 100) / 100
        zone_size = available * size_pct

        box =
          case direction do
            "vertical" ->
              %{x: padding, y: padding + offset, w: inner_w, h: zone_size}

            _ ->
              %{x: padding + offset, y: padding, w: zone_size, h: inner_h}
          end

        {acc ++ [{zone, box}], offset + zone_size + gap}
      end)

    boxes
  end

  defp render_zone_content(zone, box, resolver, label_height) do
    content = Map.get(zone, "content", [])

    case content do
      [] ->
        nil

      [%{"type" => type} | _] when type in ["qr", "barcode"] ->
        item = hd(content)
        render_code_in_zone(item, box, resolver)

      items ->
        align = Map.get(zone, "align", "left")
        valign = Map.get(zone, "valign", "top")
        render_text_stack(items, box, resolver, label_height, align, valign)
    end
  end

  defp render_code_in_zone(%{"type" => "qr"} = item, box, resolver) do
    data = resolver.(Map.get(item, "field", "code"))

    if data && data != "" do
      svg = Stowly.Codes.generate_qr_svg(data)

      if svg do
        side = min(box.w, box.h)
        x = box.x + (box.w - side) / 2
        y = box.y + (box.h - side) / 2
        embed_svg(svg, x, y, side, side)
      end
    end
  end

  defp render_code_in_zone(%{"type" => "barcode"} = item, box, resolver) do
    data = resolver.(Map.get(item, "field", "code"))

    if data && data != "" do
      case Stowly.Codes.generate_barcode_svg(data) do
        {:ok, svg} ->
          w = box.w
          h = box.h * 0.6
          x = box.x
          y = box.y + (box.h - h) / 2
          embed_svg(svg, x, y, w, h)

        _ ->
          nil
      end
    end
  end

  defp render_code_in_zone(_, _, _), do: nil

  defp render_text_stack(items, box, resolver, label_height, align, valign) do
    line_spacing = label_height * 0.03

    lines =
      items
      |> Enum.map(fn item ->
        font_size = font_size_pt(Map.get(item, "font_size", "medium"), label_height)
        font_weight = Map.get(item, "font_weight", "normal")

        value =
          case Map.get(item, "type") do
            "text" -> Map.get(item, "text", "")
            _ -> resolver.(Map.get(item, "field", "name")) || ""
          end

        %{value: value, font_size: font_size, font_weight: font_weight}
      end)
      |> Enum.reject(&(&1.value == ""))

    total_height =
      lines
      |> Enum.map(& &1.font_size)
      |> Enum.intersperse(line_spacing)
      |> Enum.sum()

    y_start =
      case valign do
        "middle" -> box.y + (box.h - total_height) / 2
        "bottom" -> box.y + box.h - total_height
        _ -> box.y
      end

    {text_anchor, x_pos} =
      case align do
        "center" -> {"middle", box.x + box.w / 2}
        "right" -> {"end", box.x + box.w}
        _ -> {"start", box.x}
      end

    {elements, _} =
      Enum.reduce(lines, {[], y_start}, fn line, {acc, y} ->
        text_y = y + line.font_size

        el =
          ~s(<text x="#{fmt(x_pos)}" y="#{fmt(text_y)}" font-size="#{fmt(line.font_size)}" font-weight="#{line.font_weight}" font-family="sans-serif" text-anchor="#{text_anchor}">#{escape_svg(line.value)}</text>)

        {acc ++ [el], text_y + line_spacing}
      end)

    Enum.join(elements, "\n    ")
  end

  defp font_size_pt("small", height), do: height * 0.08
  defp font_size_pt("medium", height), do: height * 0.12
  defp font_size_pt("large", height), do: height * 0.17
  defp font_size_pt(_, height), do: height * 0.12

  defp fmt(number) when is_float(number), do: :erlang.float_to_binary(number, decimals: 2)
  defp fmt(number), do: to_string(number)

  ## V1 to V2 migration

  @doc """
  Converts a v1 template (elements-based) to v2 zone layout format.
  """
  def migrate_template_to_v2(%{"version" => 2} = layout), do: layout

  def migrate_template_to_v2(template_map) do
    elements = Map.get(template_map, "elements", [])

    if elements == [] do
      preset_layout("qr_text")
    else
      code_elements = Enum.filter(elements, &(&1["type"] in ["qr", "barcode"]))
      text_elements = Enum.filter(elements, &(&1["type"] in ["text", "field"]))

      zones =
        case {code_elements, text_elements} do
          {[], texts} ->
            [
              %{
                "size" => 100,
                "align" => "left",
                "valign" => "top",
                "content" => Enum.map(texts, &migrate_text_element/1)
              }
            ]

          {[code | _], []} ->
            [
              %{
                "size" => 100,
                "align" => "center",
                "valign" => "middle",
                "content" => [
                  %{"type" => code["type"], "field" => Map.get(code, "field", "code")}
                ]
              }
            ]

          {[code | _], texts} ->
            [
              %{
                "size" => 35,
                "align" => "center",
                "valign" => "middle",
                "content" => [
                  %{"type" => code["type"], "field" => Map.get(code, "field", "code")}
                ]
              },
              %{
                "size" => 65,
                "align" => "left",
                "valign" => "top",
                "content" => Enum.map(texts, &migrate_text_element/1)
              }
            ]
        end

      %{
        "version" => 2,
        "padding" => 1.5,
        "gap" => 1.0,
        "direction" => "horizontal",
        "zones" => zones
      }
    end
  end

  defp migrate_text_element(%{"type" => "text"} = el) do
    %{
      "type" => "text",
      "text" => Map.get(el, "text", ""),
      "font_size" => size_to_preset(Map.get(el, "font_size", 3)),
      "font_weight" => Map.get(el, "font_weight", "normal")
    }
  end

  defp migrate_text_element(%{"type" => "field"} = el) do
    %{
      "type" => "field",
      "field" => Map.get(el, "field", "name"),
      "font_size" => size_to_preset(Map.get(el, "font_size", 3)),
      "font_weight" => Map.get(el, "font_weight", "normal")
    }
  end

  defp migrate_text_element(el), do: el

  defp size_to_preset(size) when is_number(size) and size >= 5, do: "large"
  defp size_to_preset(size) when is_number(size) and size >= 3, do: "medium"
  defp size_to_preset(_), do: "small"

  ## Preset layouts

  def preset_layout("qr_text") do
    %{
      "version" => 2,
      "padding" => 1.5,
      "gap" => 1.0,
      "direction" => "horizontal",
      "zones" => [
        %{
          "size" => 35,
          "align" => "center",
          "valign" => "middle",
          "content" => [%{"type" => "qr", "field" => "code"}]
        },
        %{
          "size" => 65,
          "align" => "left",
          "valign" => "top",
          "content" => [
            %{
              "type" => "field",
              "field" => "name",
              "font_size" => "large",
              "font_weight" => "bold"
            },
            %{
              "type" => "field",
              "field" => "category",
              "font_size" => "small",
              "font_weight" => "normal"
            },
            %{
              "type" => "field",
              "field" => "location",
              "font_size" => "small",
              "font_weight" => "normal"
            }
          ]
        }
      ]
    }
  end

  def preset_layout("text_barcode") do
    %{
      "version" => 2,
      "padding" => 1.5,
      "gap" => 1.0,
      "direction" => "vertical",
      "zones" => [
        %{
          "size" => 50,
          "align" => "center",
          "valign" => "middle",
          "content" => [
            %{
              "type" => "field",
              "field" => "name",
              "font_size" => "large",
              "font_weight" => "bold"
            },
            %{
              "type" => "field",
              "field" => "code",
              "font_size" => "small",
              "font_weight" => "normal"
            }
          ]
        },
        %{
          "size" => 50,
          "align" => "center",
          "valign" => "middle",
          "content" => [%{"type" => "barcode", "field" => "code"}]
        }
      ]
    }
  end

  def preset_layout("text_only") do
    %{
      "version" => 2,
      "padding" => 1.5,
      "gap" => 1.0,
      "direction" => "vertical",
      "zones" => [
        %{
          "size" => 100,
          "align" => "center",
          "valign" => "middle",
          "content" => [
            %{
              "type" => "field",
              "field" => "name",
              "font_size" => "large",
              "font_weight" => "bold"
            },
            %{
              "type" => "field",
              "field" => "description",
              "font_size" => "medium",
              "font_weight" => "normal"
            }
          ]
        }
      ]
    }
  end

  def preset_layout("qr_only") do
    %{
      "version" => 2,
      "padding" => 1.5,
      "gap" => 1.0,
      "direction" => "vertical",
      "zones" => [
        %{
          "size" => 100,
          "align" => "center",
          "valign" => "middle",
          "content" => [%{"type" => "qr", "field" => "code"}]
        }
      ]
    }
  end

  def preset_layout(_) do
    %{
      "version" => 2,
      "padding" => 1.5,
      "gap" => 1.0,
      "direction" => "horizontal",
      "zones" => []
    }
  end

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
        ~s(<svg x="#{fmt(x)}" y="#{fmt(y)}" width="#{fmt(w)}" height="#{fmt(h)}" viewBox="\\1">)
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
