defmodule Stowly.Backup do
  @moduledoc """
  Backup and restore functionality.

  Creates .tgz archives containing JSON exports of all data
  and optionally the uploads directory.
  """
  import Ecto.Query
  alias Stowly.Repo

  @tables [
    {Stowly.Inventory.Collection, "collections"},
    {Stowly.Inventory.Category, "categories"},
    {Stowly.Inventory.Tag, "tags"},
    {Stowly.Inventory.CustomFieldDefinition, "custom_field_definitions"},
    {Stowly.Inventory.StorageLocation, "storage_locations"},
    {Stowly.Inventory.Item, "items"},
    {Stowly.Inventory.CustomFieldValue, "custom_field_values"},
    {Stowly.Inventory.ItemPrice, "item_prices"},
    {Stowly.Inventory.Medium, "media"},
    {Stowly.Labels.LabelTemplate, "label_templates"}
  ]

  # Also export item_tags join table
  @item_tags_query from(it in "item_tags", select: %{item_id: it.item_id, tag_id: it.tag_id})

  def create_backup(opts \\ []) do
    include_media = Keyword.get(opts, :include_media, false)
    tmp_dir = Path.join(System.tmp_dir!(), "stowly_backup_#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(tmp_dir, "data"))

    manifest = %{
      "version" => 1,
      "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "includes_media" => include_media
    }

    write_json(Path.join(tmp_dir, "manifest.json"), manifest)

    for {schema, name} <- @tables do
      records =
        schema
        |> order_by(asc: :id)
        |> Repo.all()
        |> Enum.map(&schema_to_map/1)

      write_json(Path.join([tmp_dir, "data", "#{name}.json"]), records)
    end

    item_tags = Repo.all(@item_tags_query)
    write_json(Path.join([tmp_dir, "data", "item_tags.json"]), item_tags)

    files = collect_files(tmp_dir, "")

    files =
      if include_media do
        uploads_dir = Stowly.Uploads.uploads_dir()

        if File.exists?(uploads_dir) do
          upload_files = collect_files(uploads_dir, "")

          upload_entries =
            Enum.map(upload_files, fn rel -> {"uploads/#{rel}", Path.join(uploads_dir, rel)} end)

          files ++ upload_entries
        else
          files
        end
      else
        files
      end

    date = Date.utc_today() |> Date.to_iso8601()
    archive_name = "backup_#{date}.tgz"
    archive_path = Path.join(System.tmp_dir!(), archive_name)

    tar_files =
      Enum.map(files, fn
        {name, path} -> {String.to_charlist(name), String.to_charlist(path)}
        rel -> {String.to_charlist(rel), String.to_charlist(Path.join(tmp_dir, rel))}
      end)

    :ok = :erl_tar.create(String.to_charlist(archive_path), tar_files, [:compressed])

    File.rm_rf!(tmp_dir)

    {:ok, archive_path, archive_name}
  end

  def restore_backup(archive_path) do
    tmp_dir = Path.join(System.tmp_dir!(), "stowly_restore_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)

    case :erl_tar.extract(String.to_charlist(archive_path), [
           :compressed,
           {:cwd, String.to_charlist(tmp_dir)}
         ]) do
      {:error, reason} ->
        File.rm_rf!(tmp_dir)
        {:error, "Invalid archive: #{inspect(reason)}"}

      :ok ->
        do_restore(tmp_dir)
    end
  end

  defp do_restore(tmp_dir) do
    manifest_path = Path.join(tmp_dir, "manifest.json")

    unless File.exists?(manifest_path) do
      File.rm_rf!(tmp_dir)
      {:error, "Invalid backup: missing manifest.json"}
    else
      manifest = read_json(manifest_path)

      Repo.transaction(fn ->
        clear_all_data()
        restore_data(tmp_dir)
      end)

      if Map.get(manifest, "includes_media", false) do
        restore_media(tmp_dir)
      end

      File.rm_rf!(tmp_dir)
      :ok
    end
  end

  defp clear_all_data do
    for {schema, _name} <- Enum.reverse(@tables) do
      Repo.delete_all(schema)
    end

    Repo.delete_all(from(it in "item_tags"))
  end

  defp restore_data(tmp_dir) do
    for {schema, name} <- @tables do
      path = Path.join([tmp_dir, "data", "#{name}.json"])

      if File.exists?(path) do
        records = read_json(path)

        for record <- records do
          attrs = prepare_attrs(record)

          schema
          |> struct()
          |> Ecto.Changeset.change(attrs)
          |> Repo.insert!()
        end
      end
    end

    item_tags_path = Path.join([tmp_dir, "data", "item_tags.json"])

    if File.exists?(item_tags_path) do
      item_tags = read_json(item_tags_path)

      for tag <- item_tags do
        Repo.insert_all("item_tags", [
          %{
            item_id: tag["item_id"],
            tag_id: tag["tag_id"]
          }
        ])
      end
    end
  end

  defp restore_media(tmp_dir) do
    uploads_src = Path.join(tmp_dir, "uploads")

    if File.exists?(uploads_src) do
      uploads_dest = Stowly.Uploads.uploads_dir()
      File.mkdir_p!(uploads_dest)

      collect_files(uploads_src, "")
      |> Enum.each(fn rel ->
        src = Path.join(uploads_src, rel)
        dest = Path.join(uploads_dest, rel)
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(src, dest)
      end)
    end
  end

  defp schema_to_map(record) do
    record
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> Map.new(fn
      {k, %DateTime{} = v} -> {k, DateTime.to_iso8601(v)}
      {k, %NaiveDateTime{} = v} -> {k, NaiveDateTime.to_iso8601(v)}
      {k, %Ecto.Association.NotLoaded{}} -> {k, nil}
      {k, v} -> {k, v}
    end)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp prepare_attrs(record) do
    record
    |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> Map.drop([:__meta__])
    |> Map.new(fn
      {:inserted_at, v} when is_binary(v) -> {:inserted_at, parse_datetime(v)}
      {:updated_at, v} when is_binary(v) -> {:updated_at, parse_datetime(v)}
      other -> other
    end)
  end

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _offset} ->
        DateTime.truncate(dt, :second)

      _ ->
        case NaiveDateTime.from_iso8601(str) do
          {:ok, ndt} -> DateTime.from_naive!(ndt, "Etc/UTC")
          _ -> DateTime.utc_now() |> DateTime.truncate(:second)
        end
    end
  end

  defp write_json(path, data) do
    File.write!(path, Jason.encode!(data, pretty: true))
  end

  defp read_json(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end

  defp collect_files(dir, prefix) do
    dir
    |> File.ls!()
    |> Enum.flat_map(fn entry ->
      full_path = Path.join(dir, entry)
      relative = if prefix == "", do: entry, else: Path.join(prefix, entry)

      if File.dir?(full_path) do
        collect_files(full_path, relative)
      else
        [relative]
      end
    end)
  end
end
