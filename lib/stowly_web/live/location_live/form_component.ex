defmodule StowlyWeb.LocationLive.FormComponent do
  use StowlyWeb, :live_component

  alias Stowly.Inventory
  alias Stowly.Inventory.StorageLocation

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-bold mb-4">{@title}</h3>

      <.simple_form
        for={@form}
        id="location-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" placeholder="e.g., Living Room Shelf" />
        <.input field={@form[:location_type]} type="select" label="Type">
          <option :for={t <- StorageLocation.location_types()} value={t}>
            {String.capitalize(t)}
          </option>
        </.input>
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:parent_id]} type="select" label="Parent Location">
          <option value="">None (top-level)</option>
          <option
            :for={loc <- @all_locations}
            :if={loc.id != (@location && @location.id)}
            value={loc.id}
          >
            {loc.name} ({loc.location_type})
          </option>
        </.input>

        <:actions>
          <.button type="submit" class="btn-primary" phx-disable-with="Saving...">
            Save Location
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{location: location} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventory.change_storage_location(location))
     end)}
  end

  @impl true
  def handle_event("validate", %{"storage_location" => params}, socket) do
    changeset =
      socket.assigns.location
      |> Inventory.change_storage_location(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"storage_location" => params}, socket) do
    save_location(socket, socket.assigns.action, params)
  end

  defp save_location(socket, :edit, params) do
    case Inventory.update_storage_location(socket.assigns.location, params) do
      {:ok, location} ->
        notify_parent({:saved, location})

        {:noreply,
         socket
         |> put_flash(:info, "Location updated")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_location(socket, :new, params) do
    case Inventory.create_storage_location(socket.assigns.collection, params) do
      {:ok, location} ->
        notify_parent({:saved, location})

        {:noreply,
         socket
         |> put_flash(:info, "Location created")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
