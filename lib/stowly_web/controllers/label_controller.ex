defmodule StowlyWeb.LabelController do
  use StowlyWeb, :controller

  alias Stowly.Inventory
  alias Stowly.Labels

  def print(conn, %{"collection_id" => collection_id, "id" => template_id} = params) do
    collection = Inventory.get_collection!(collection_id)
    template = Labels.get_label_template!(template_id)

    item_ids =
      case Map.get(params, "item_ids", []) do
        ids when is_list(ids) -> Enum.map(ids, &String.to_integer/1)
        id when is_binary(id) -> [String.to_integer(id)]
        _ -> []
      end

    items =
      Inventory.list_items(collection)
      |> Enum.filter(&(&1.id in item_ids))

    labels = Enum.map(items, &Labels.render_label(template, &1))

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, render_print_page(template, labels))
  end

  defp render_print_page(template, labels) do
    labels_html =
      labels
      |> Enum.map(fn svg ->
        ~s(<div class="label">#{svg}</div>)
      end)
      |> Enum.join("\n")

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Print Labels - #{escape_html(template.name)}</title>
      <style>
        @page {
          size: #{template.width_mm}mm #{template.height_mm}mm;
          margin: 0;
        }

        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        body {
          font-family: sans-serif;
        }

        .label {
          width: #{template.width_mm}mm;
          height: #{template.height_mm}mm;
          page-break-after: always;
          overflow: hidden;
        }

        .label svg {
          width: 100%;
          height: 100%;
        }

        @media screen {
          body {
            background: #f0f0f0;
            padding: 20px;
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            justify-content: center;
          }

          .label {
            background: white;
            box-shadow: 0 1px 3px rgba(0,0,0,0.12);
            page-break-after: auto;
          }
        }
      </style>
    </head>
    <body>
      #{labels_html}
      <script>window.onload = function() { window.print(); }</script>
    </body>
    </html>
    """
  end

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp escape_html(_), do: ""
end
