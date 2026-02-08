defmodule StowlyWeb.LabelLive.Index do
  use StowlyWeb, :live_view

  alias Stowly.Inventory
  alias Stowly.Labels
  alias Stowly.Labels.LabelTemplate

  @impl true
  def mount(%{"collection_id" => collection_id}, _session, socket) do
    collection = Inventory.get_collection!(collection_id)
    templates = Labels.list_label_templates(collection)

    {:ok,
     assign(socket,
       collection: collection,
       templates: templates,
       page_title: "Label Templates"
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    assign(socket,
      template: %LabelTemplate{collection_id: socket.assigns.collection.id},
      modal_title: "New Label Template"
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    template = Labels.get_label_template!(id)

    assign(socket,
      template: template,
      modal_title: "Edit Label Template"
    )
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, template: nil, modal_title: nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    template = Labels.get_label_template!(id)
    {:ok, _} = Labels.delete_label_template(template)

    {:noreply,
     assign(socket,
       templates: Labels.list_label_templates(socket.assigns.collection)
     )}
  end

  @impl true
  def handle_info({StowlyWeb.LabelLive.FormComponent, {:saved, _template}}, socket) do
    {:noreply,
     assign(socket,
       templates: Labels.list_label_templates(socket.assigns.collection)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.theme_applicator theme={@collection.theme} />
    <.back navigate={~p"/collections/#{@collection}"}>Collection</.back>

    <.header>
      Label Templates
      <:actions>
        <.link
          patch={~p"/collections/#{@collection}/labels/new"}
          class="btn btn-primary btn-sm"
        >
          <.icon name="hero-plus" class="h-4 w-4" /> New Template
        </.link>
      </:actions>
    </.header>

    <div :if={@templates == []} class="text-center py-12 text-base-content/50">
      <.icon name="hero-tag" class="h-12 w-12 mx-auto mb-4" />
      <p>No label templates yet.</p>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
      <div :for={template <- @templates} class="card bg-base-200">
        <div class="card-body">
          <h3 class="card-title text-sm">
            {template.name}
            <span :if={template.is_default} class="badge badge-primary badge-sm">Default</span>
          </h3>
          <p :if={template.description} class="text-sm text-base-content/70">
            {template.description}
          </p>
          <p class="text-xs text-base-content/50">
            {template.width_mm}mm x {template.height_mm}mm
          </p>
          <div class="card-actions justify-end mt-2">
            <.link
              navigate={~p"/collections/#{@collection}/labels/#{template}"}
              class="btn btn-ghost btn-xs"
            >
              <.icon name="hero-eye" class="h-3 w-3" /> Preview
            </.link>
            <.link
              patch={~p"/collections/#{@collection}/labels/#{template}/edit"}
              class="btn btn-ghost btn-xs"
            >
              <.icon name="hero-pencil-square" class="h-3 w-3" /> Edit
            </.link>
            <button
              class="btn btn-ghost btn-xs text-error"
              phx-click="delete"
              phx-value-id={template.id}
              data-confirm="Delete this template?"
            >
              <.icon name="hero-trash" class="h-3 w-3" />
            </button>
          </div>
        </div>
      </div>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="template-modal"
      show
      on_cancel={JS.patch(~p"/collections/#{@collection}/labels")}
    >
      <.live_component
        module={StowlyWeb.LabelLive.FormComponent}
        id={@template.id || :new}
        title={@modal_title}
        action={@live_action}
        template={@template}
        collection={@collection}
        patch={~p"/collections/#{@collection}/labels"}
      />
    </.modal>
    """
  end
end
