defmodule Stowly.Uploads do
  @moduledoc """
  Handles file storage for uploaded media.
  Files are stored at `uploads/<year>/<month>/<item_id>/<uuid>.<ext>`.
  """

  def uploads_dir do
    Application.get_env(:stowly, :uploads_dir, "uploads")
  end

  def store(%{path: tmp_path, client_name: original_filename, client_type: content_type}, item_id) do
    ext = Path.extname(original_filename)
    uuid = Ecto.UUID.generate()
    now = DateTime.utc_now()
    year = Integer.to_string(now.year)
    month = now.month |> Integer.to_string() |> String.pad_leading(2, "0")

    relative_dir = Path.join([year, month, Integer.to_string(item_id)])
    full_dir = Path.join(uploads_dir(), relative_dir)
    File.mkdir_p!(full_dir)

    filename = "#{uuid}#{ext}"
    relative_path = Path.join(relative_dir, filename)
    full_path = Path.join(uploads_dir(), relative_path)

    File.cp!(tmp_path, full_path)

    size_bytes = File.stat!(full_path).size

    %{
      filename: filename,
      original_filename: original_filename,
      content_type: content_type,
      size_bytes: size_bytes,
      file_path: relative_path
    }
  end

  def delete(relative_path) do
    full_path = Path.join(uploads_dir(), relative_path)

    if File.exists?(full_path) do
      File.rm(full_path)
    else
      :ok
    end
  end

  def url(relative_path) do
    "/uploads/#{relative_path}"
  end
end
