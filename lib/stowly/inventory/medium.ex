defmodule Stowly.Inventory.Medium do
  use Ecto.Schema
  import Ecto.Changeset

  schema "media" do
    field :filename, :string
    field :original_filename, :string
    field :content_type, :string
    field :size_bytes, :integer
    field :file_path, :string
    field :thumbnail_path, :string
    field :caption, :string
    field :position, :integer, default: 0

    belongs_to :item, Stowly.Inventory.Item

    timestamps(type: :utc_datetime)
  end

  def changeset(medium, attrs) do
    medium
    |> cast(attrs, [
      :filename,
      :original_filename,
      :content_type,
      :size_bytes,
      :file_path,
      :thumbnail_path,
      :caption,
      :position
    ])
    |> validate_required([:filename, :original_filename, :content_type, :file_path])
  end
end
