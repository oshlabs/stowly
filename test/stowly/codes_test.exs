defmodule Stowly.CodesTest do
  use ExUnit.Case, async: true

  alias Stowly.Codes

  describe "generate_qr_svg/1" do
    test "generates SVG for valid data" do
      svg = Codes.generate_qr_svg("hello")
      assert is_binary(svg)
      assert svg =~ "<svg"
      assert svg =~ "</svg>"
    end

    test "returns nil for empty string" do
      assert Codes.generate_qr_svg("") == nil
    end

    test "returns nil for nil" do
      assert Codes.generate_qr_svg(nil) == nil
    end
  end

  describe "generate_barcode_svg/2" do
    test "generates Code128 SVG by default" do
      assert {:ok, svg} = Codes.generate_barcode_svg("12345")
      assert is_binary(svg)
      assert svg =~ "<svg"
    end

    test "generates Code128 SVG explicitly" do
      assert {:ok, svg} = Codes.generate_barcode_svg("ABC123", :code128)
      assert is_binary(svg)
      assert svg =~ "<svg"
    end

    test "generates Code39 SVG" do
      assert {:ok, svg} = Codes.generate_barcode_svg("ABC123", :code39)
      assert is_binary(svg)
      assert svg =~ "<svg"
    end

    test "returns error for unsupported type" do
      assert {:error, :unsupported_type} = Codes.generate_barcode_svg("test", :unknown)
    end

    test "returns nil for empty string" do
      assert Codes.generate_barcode_svg("") == nil
    end

    test "returns nil for nil" do
      assert Codes.generate_barcode_svg(nil) == nil
    end
  end
end
