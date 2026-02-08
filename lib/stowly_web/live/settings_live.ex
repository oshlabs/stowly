defmodule StowlyWeb.SettingsLive do
  use StowlyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Settings",
       backup_status: nil,
       restore_status: nil,
       include_media: false
     )
     |> allow_upload(:backup_file,
       accept: ~w(.tgz .tar.gz),
       max_entries: 1,
       max_file_size: 500_000_000
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_media", _params, socket) do
    {:noreply, assign(socket, include_media: !socket.assigns.include_media)}
  end

  def handle_event("create_backup", _params, socket) do
    {:ok, path, filename} =
      Stowly.Backup.create_backup(include_media: socket.assigns.include_media)

    {:noreply,
     socket
     |> assign(backup_status: {:ok, path, filename})
     |> put_flash(:info, "Backup created successfully")}
  end

  def handle_event("restore", _params, socket) do
    [entry] = socket.assigns.uploads.backup_file.entries

    consume_uploaded_entry(socket, entry, fn %{path: tmp_path} ->
      case Stowly.Backup.restore_backup(tmp_path) do
        :ok ->
          {:ok, :restored}

        {:error, reason} ->
          {:ok, {:error, reason}}
      end
    end)
    |> case do
      :restored ->
        {:noreply,
         socket
         |> assign(restore_status: :ok)
         |> put_flash(:info, "Backup restored successfully")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(restore_status: {:error, reason})
         |> put_flash(:error, "Restore failed: #{inspect(reason)}")}
    end
  end

  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Settings
    </.header>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
      <div class="card bg-base-200">
        <div class="card-body">
          <h3 class="card-title">
            <.icon name="hero-arrow-down-tray" class="h-5 w-5" /> Create Backup
          </h3>
          <p class="text-sm text-base-content/70">
            Export all collections, items, and settings as a downloadable archive.
          </p>

          <label class="flex items-center gap-2 mt-2 cursor-pointer">
            <input
              type="checkbox"
              class="checkbox checkbox-sm"
              checked={@include_media}
              phx-click="toggle_media"
            />
            <span class="text-sm">Include uploaded photos</span>
          </label>

          <div class="card-actions mt-4">
            <button class="btn btn-primary btn-sm" phx-click="create_backup">
              <.icon name="hero-arrow-down-tray" class="h-4 w-4" /> Create Backup
            </button>
          </div>

          <div :if={match?({:ok, _, _}, @backup_status)} class="alert alert-success mt-2">
            <.icon name="hero-check-circle" class="h-5 w-5" />
            <div>
              <p class="font-medium">Backup ready!</p>
              <a
                href={download_path(elem(@backup_status, 1), elem(@backup_status, 2))}
                download={elem(@backup_status, 2)}
                class="link"
              >
                Download {elem(@backup_status, 2)}
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-base-200">
        <div class="card-body">
          <h3 class="card-title">
            <.icon name="hero-arrow-up-tray" class="h-5 w-5" /> Restore Backup
          </h3>
          <p class="text-sm text-base-content/70">
            Restore all data from a previously created backup archive.
            This will replace all existing data.
          </p>

          <div class="alert alert-warning mt-2">
            <.icon name="hero-exclamation-triangle" class="h-5 w-5" />
            <span class="text-sm">Restoring will delete all current data!</span>
          </div>

          <form phx-submit="restore" phx-change="validate_upload" class="mt-4">
            <.live_file_input upload={@uploads.backup_file} class="file-input file-input-bordered file-input-sm w-full" />

            <div :for={entry <- @uploads.backup_file.entries} class="text-sm mt-2">
              {entry.client_name} ({format_bytes(entry.client_size)})
              <div :for={err <- upload_errors(@uploads.backup_file, entry)} class="text-error text-xs">
                {error_to_string(err)}
              </div>
            </div>

            <button
              type="submit"
              class="btn btn-warning btn-sm mt-4"
              disabled={@uploads.backup_file.entries == []}
              data-confirm="This will delete all existing data and restore from the backup. Continue?"
            >
              <.icon name="hero-arrow-up-tray" class="h-4 w-4" /> Restore
            </button>
          </form>

          <div :if={@restore_status == :ok} class="alert alert-success mt-2">
            <.icon name="hero-check-circle" class="h-5 w-5" />
            <span>Data restored successfully!</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp download_path(path, filename) do
    "/backup/download?path=#{URI.encode(path)}&filename=#{URI.encode(filename)}"
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_bytes(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  defp error_to_string(:too_large), do: "File is too large (max 500MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted (use .tgz or .tar.gz)"
  defp error_to_string(err), do: inspect(err)
end
