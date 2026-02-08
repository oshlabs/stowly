defmodule StowlyWeb.CodeDisplayComponent do
  use StowlyWeb, :html

  alias Stowly.Codes

  attr :data, :string, required: true
  attr :type, :atom, default: :qr, values: [:qr, :barcode]

  def code_display(assigns) do
    assigns = assign(assigns, :svg, generate_svg(assigns.data, assigns.type))

    ~H"""
    <div :if={@svg} class="inline-block">
      {Phoenix.HTML.raw(@svg)}
    </div>
    """
  end

  defp generate_svg(data, :qr) when is_binary(data) and data != "" do
    Codes.generate_qr_svg(data)
  end

  defp generate_svg(data, :barcode) when is_binary(data) and data != "" do
    case Codes.generate_barcode_svg(data) do
      {:ok, svg} -> IO.iodata_to_binary(svg)
      _ -> nil
    end
  end

  defp generate_svg(_, _), do: nil
end
