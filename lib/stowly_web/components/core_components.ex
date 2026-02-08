defmodule StowlyWeb.CoreComponents do
  @moduledoc """
  Provides core UI components styled with daisyUI.
  """
  use Phoenix.Component
  use Gettext, backend: StowlyWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal using daisyUI dialog.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={@on_cancel}
      class="hidden"
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-black/50 z-40" aria-hidden="true" />
      <div
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
        phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
        phx-key="escape"
      >
        <div
          id={"#{@id}-container"}
          class="bg-base-100 rounded-box shadow-xl max-w-lg w-full max-h-[90vh] overflow-y-auto p-6 relative"
          phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
        >
          <button
            class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  def show_modal(id) do
    JS.show(to: "##{id}")
    |> JS.show(to: "##{id}-bg", transition: {"ease-out duration-200", "opacity-0", "opacity-100"})
    |> JS.show(
      to: "##{id}-container",
      transition: {"ease-out duration-200", "opacity-0 scale-95", "opacity-100 scale-100"}
    )
    |> JS.focus_first(to: "##{id}-container")
  end

  def hide_modal(id) do
    JS.hide(to: "##{id}-bg", transition: {"ease-in duration-100", "opacity-100", "opacity-0"})
    |> JS.hide(
      to: "##{id}-container",
      transition: {"ease-in duration-100", "opacity-100 scale-100", "opacity-0 scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
  end

  @doc """
  Renders flash messages.
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :title, :string, default: nil
  attr :rest, :global

  slot :inner_block

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      role="alert"
      class={[
        "alert shadow-lg mb-4",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}
      {@rest}
    >
      <.icon :if={@kind == :info} name="hero-information-circle" class="h-6 w-6" />
      <.icon :if={@kind == :error} name="hero-exclamation-circle" class="h-6 w-6" />
      <div>
        <h3 :if={@title} class="font-bold">{@title}</h3>
        <div class="text-sm">{msg}</div>
      </div>
      <button
        type="button"
        class="btn btn-sm btn-ghost"
        aria-label={gettext("close")}
        phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.hide(to: "##{@id}")}
      >
        <.icon name="hero-x-mark" class="h-5 w-5" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash messages as a group.
  """
  attr :flash, :map, required: true

  def flash_group(assigns) do
    ~H"""
    <div class="w-full">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={JS.show(to: "#client-error")}
        phx-connected={JS.hide(to: "#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={JS.show(to: "#server-error")}
        phx-connected={JS.hide(to: "#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart)

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-4">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="flex items-center justify-between gap-4 mt-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} class={["btn", @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text"
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"
  attr :errors, :list, default: []

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <fieldset class="fieldset">
      <label :if={@label} class="fieldset-label" for={@id}>{@label}</label>
      <select id={@id} name={@name} class="select select-bordered w-full" {@rest}>
        {render_slot(@inner_block)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <fieldset class="fieldset">
      <label :if={@label} class="fieldset-label" for={@id}>{@label}</label>
      <textarea id={@id} name={@name} class="textarea textarea-bordered w-full" {@rest}>{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <fieldset class="fieldset">
      <label class="label cursor-pointer gap-2">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="checkbox"
          {@rest}
        />
        <span :if={@label} class="label-text">{@label}</span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  def input(assigns) do
    ~H"""
    <fieldset class="fieldset">
      <label :if={@label} class="fieldset-label" for={@id}>{@label}</label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class="input input-bordered w-full"
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  @color_presets ~w(#ef4444 #f97316 #f59e0b #22c55e #14b8a6 #3b82f6 #6366f1 #a855f7 #ec4899 #64748b)

  @doc """
  Renders a text input with a color picker dropdown.
  """
  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil

  def color_input(assigns) do
    field = assigns.field
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(:id, field.id)
      |> assign(:name, field.name)
      |> assign(:value, field.value || "")
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign(:presets, @color_presets)

    ~H"""
    <fieldset class="fieldset">
      <label :if={@label} class="fieldset-label" for={@id}>{@label}</label>
      <div id={"#{@id}-color-picker"} phx-hook="ColorPickerHook" class="relative">
        <div class="flex items-center gap-2">
          <input
            type="text"
            name={@name}
            id={@id}
            value={@value}
            class="input input-bordered w-full"
            placeholder="#3b82f6"
          />
          <button
            type="button"
            data-swatch
            class="w-10 h-10 rounded border-2 border-base-300 cursor-pointer shrink-0"
            style={"background-color: #{if @value != "", do: @value, else: "transparent"}"}
          >
          </button>
        </div>
        <div data-panel class="hidden absolute right-0 z-50 mt-2 p-3 bg-base-100 rounded-box shadow-xl border border-base-300 w-64">
          <div class="grid grid-cols-5 gap-2 mb-3">
            <button
              :for={color <- @presets}
              type="button"
              data-preset={color}
              class="w-10 h-10 rounded cursor-pointer border border-base-300"
              style={"background-color: #{color}"}
            >
            </button>
          </div>
          <div class="flex items-center gap-2 mb-3">
            <span class="text-xs text-base-content/60">Custom:</span>
            <input type="color" class="w-8 h-8 rounded cursor-pointer border-0 p-0" />
          </div>
          <div class="flex justify-end gap-2">
            <button type="button" data-cancel class="btn btn-ghost btn-xs">Cancel</button>
            <button type="button" data-ok class="btn btn-primary btn-xs">OK</button>
          </div>
        </div>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="label">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="text-error text-sm mt-1">
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={["mb-6", @class]}>
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold">
            {render_slot(@inner_block)}
          </h1>
          <p :if={@subtitle != []} class="text-base-content/70 mt-1">
            {render_slot(@subtitle)}
          </p>
        </div>
        <div :if={@actions != []} class="flex gap-2">
          {render_slot(@actions)}
        </div>
      </div>
    </header>
    """
  end

  @doc """
  Renders a data table.
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-x-auto">
      <table class="table">
        <thead>
          <tr>
            <th :for={col <- @col}>{col[:label]}</th>
            <th :if={@action != []}><span class="sr-only">{gettext("Actions")}</span></th>
          </tr>
        </thead>
        <tbody id={@id} phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}>
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="hover">
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={@row_click && "cursor-pointer"}
            >
              {render_slot(col, @row_id && @row_id.(row) |> then(fn _ -> row end) || row)}
            </td>
            <td :if={@action != []}>
              <div class="flex gap-2 justify-end">
                <span :for={action <- @action}>
                  {render_slot(action, @row_id && @row_id.(row) |> then(fn _ -> row end) || row)}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.
  """
  attr :navigate, :any, required: true
  slot :inner_block

  def back(assigns) do
    ~H"""
    <div class="mb-4">
      <.link navigate={@navigate} class="btn btn-ghost btn-sm gap-1">
        <.icon name="hero-arrow-left" class="h-4 w-4" />
        {render_slot(@inner_block) || gettext("Back")}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a heroicon.
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(StowlyWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(StowlyWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
