defmodule Stowly.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media) do
      add :item_id, references(:items, on_delete: :delete_all), null: false
      add :filename, :string, null: false
      add :original_filename, :string, null: false
      add :content_type, :string, null: false
      add :size_bytes, :integer
      add :file_path, :string, null: false
      add :thumbnail_path, :string
      add :caption, :string
      add :position, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:media, [:item_id])
  end
end
