defmodule StowlyWeb.ThemeComponent do
  use Phoenix.Component

  @doc """
  Renders a hidden element that applies the collection's theme via a JS hook.
  Include this in any LiveView that has a `@collection` assign with theme data.

  The theme map can contain:
  - "base_theme" - a daisyUI theme name ("light", "dark", etc.)
  - "primary", "secondary", "accent", "neutral" - custom color overrides (oklch values)
  """
  attr :theme, :map, default: %{}

  def theme_applicator(assigns) do
    base_theme = Map.get(assigns.theme || %{}, "base_theme")
    overrides = build_overrides(assigns.theme || %{})

    assigns =
      assigns
      |> assign(:base_theme, base_theme)
      |> assign(:overrides_json, if(overrides != %{}, do: Jason.encode!(overrides), else: nil))

    ~H"""
    <div
      :if={@base_theme || @overrides_json}
      id="collection-theme"
      phx-hook="ThemeHook"
      data-base-theme={@base_theme}
      data-theme-overrides={@overrides_json}
      class="hidden"
    />
    """
  end

  @color_mappings %{
    "primary" => "--color-primary",
    "primary_content" => "--color-primary-content",
    "secondary" => "--color-secondary",
    "secondary_content" => "--color-secondary-content",
    "accent" => "--color-accent",
    "accent_content" => "--color-accent-content",
    "neutral" => "--color-neutral",
    "neutral_content" => "--color-neutral-content",
    "base_100" => "--color-base-100",
    "base_200" => "--color-base-200",
    "base_300" => "--color-base-300",
    "base_content" => "--color-base-content"
  }

  defp build_overrides(theme) when is_map(theme) do
    @color_mappings
    |> Enum.reduce(%{}, fn {key, css_var}, acc ->
      case Map.get(theme, key) do
        nil -> acc
        "" -> acc
        value -> Map.put(acc, css_var, value)
      end
    end)
  end

  defp build_overrides(_), do: %{}
end
