defmodule StowlyWeb.CollectionLive.FormComponent do
  use StowlyWeb, :live_component

  alias Stowly.Inventory

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-bold mb-4">{@title}</h3>

      <.simple_form
        for={@form}
        id="collection-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" placeholder="e.g., Electronics, Stamps" />
        <.input field={@form[:description]} type="textarea" label="Description" placeholder="What's in this collection?" />
        <.input field={@form[:icon]} type="text" label="Icon" placeholder="Emoji, e.g. 📦" />

        <:actions>
          <.button type="submit" class="btn-primary" phx-disable-with="Saving...">
            Save Collection
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{collection: collection} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_collection(collection))
     end)}
  end

  @impl true
  def handle_event("validate", %{"collection" => collection_params}, socket) do
    changeset = Inventory.change_collection(socket.assigns.collection, collection_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"collection" => collection_params}, socket) do
    save_collection(socket, socket.assigns.action, collection_params)
  end

  defp save_collection(socket, :edit, collection_params) do
    case Inventory.update_collection(socket.assigns.collection, collection_params) do
      {:ok, collection} ->
        notify_parent({:saved, collection})

        {:noreply,
         socket
         |> put_flash(:info, "Collection updated")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_collection(socket, :new, collection_params) do
    case Inventory.create_collection(collection_params) do
      {:ok, collection} ->
        notify_parent({:saved, collection})

        {:noreply,
         socket
         |> put_flash(:info, "Collection created")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
