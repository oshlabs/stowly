defmodule Stowly.Codes do
  @moduledoc """
  QR code and barcode generation.
  """

  def generate_qr_svg(data) when is_binary(data) and data != "" do
    data
    |> EQRCode.encode()
    |> EQRCode.svg(width: 200)
  end

  def generate_qr_svg(_), do: nil

  def generate_barcode_svg(data, type \\ :code128)

  def generate_barcode_svg(data, type) when is_binary(data) and data != "" do
    case type do
      :code128 ->
        with {:ok, code} <- Barlix.Code128.encode(data),
             {:ok, svg} <- Barlix.SVG.print(code, height: 50, xdim: 2) do
          {:ok, svg}
        end

      :code39 ->
        with {:ok, code} <- Barlix.Code39.encode(data),
             {:ok, svg} <- Barlix.SVG.print(code, height: 50, xdim: 2) do
          {:ok, svg}
        end

      _ ->
        {:error, :unsupported_type}
    end
  end

  def generate_barcode_svg(_, _), do: nil
end
