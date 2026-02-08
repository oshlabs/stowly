defmodule StowlyWeb.ItemLive.MediaComponent do
  use StowlyWeb, :live_component

  alias Stowly.Inventory
  alias Stowly.Uploads

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3 class="font-bold mb-3">Photos</h3>

      <div :if={@media == []} class="text-base-content/50 text-sm mb-4">
        No photos yet. Upload one below.
      </div>

      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 mb-4">
        <div :for={medium <- @media} class="relative group">
          <img
            src={Uploads.url(medium.file_path)}
            alt={medium.caption || medium.original_filename}
            class="rounded-lg w-full h-32 object-cover"
          />
          <button
            type="button"
            class="absolute top-1 right-1 btn btn-circle btn-xs btn-error opacity-0 group-hover:opacity-100 transition-opacity"
            phx-click="delete_medium"
            phx-value-id={medium.id}
            phx-target={@myself}
            data-confirm="Delete this photo?"
          >
            <.icon name="hero-x-mark" class="h-3 w-3" />
          </button>
          <p :if={medium.caption} class="text-xs text-base-content/70 mt-1 truncate">
            {medium.caption}
          </p>
        </div>
      </div>

      <form id="upload-form" phx-submit="save_upload" phx-change="validate_upload" phx-target={@myself}>
        <.live_file_input upload={@uploads.photos} class="file-input file-input-bordered file-input-sm w-full" />

        <div :for={entry <- @uploads.photos.entries} class="flex items-center gap-2 mt-2">
          <.live_img_preview entry={entry} class="h-12 w-12 rounded object-cover" />
          <span class="text-sm flex-1">{entry.client_name}</span>
          <progress class="progress progress-primary w-20" value={entry.progress} max="100" />
          <button
            type="button"
            class="btn btn-ghost btn-xs"
            phx-click="cancel_upload"
            phx-value-ref={entry.ref}
            phx-target={@myself}
          >
            <.icon name="hero-x-mark" class="h-3 w-3" />
          </button>
        </div>

        <div :for={err <- upload_errors(@uploads.photos)} class="text-error text-sm mt-1">
          {error_to_string(err)}
        </div>

        <button
          :if={@uploads.photos.entries != []}
          type="submit"
          class="btn btn-primary btn-sm mt-2"
        >
          Upload
        </button>
      </form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:media, Inventory.list_media(assigns.item))
     |> allow_upload(:photos,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 10,
       max_file_size: 20_000_000
     )}
  end

  @impl true
  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save_upload", _params, socket) do
    item = socket.assigns.item

    uploaded_files =
      consume_uploaded_entries(socket, :photos, fn %{path: path} = _meta, entry ->
        attrs =
          Uploads.store(
            %{path: path, client_name: entry.client_name, client_type: entry.client_type},
            item.id
          )

        {:ok, _medium} = Inventory.create_medium(item, attrs)
        {:ok, attrs}
      end)

    {:noreply,
     socket
     |> assign(:media, Inventory.list_media(item))
     |> then(fn s ->
       if uploaded_files != [] do
         put_flash(s, :info, "#{length(uploaded_files)} photo(s) uploaded")
       else
         s
       end
     end)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  def handle_event("delete_medium", %{"id" => id}, socket) do
    medium = Inventory.get_medium!(id)
    {:ok, _} = Inventory.delete_medium(medium)

    {:noreply,
     socket
     |> assign(:media, Inventory.list_media(socket.assigns.item))
     |> put_flash(:info, "Photo deleted")}
  end

  defp error_to_string(:too_large), do: "File is too large (max 20MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(:too_many_files), do: "Too many files (max 10)"
  defp error_to_string(err), do: "Error: #{inspect(err)}"
end
