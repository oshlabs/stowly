defmodule Stowly.Inventory.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :name, :string
    field :slug, :string
    field :color, :string

    belongs_to :collection, Stowly.Inventory.Collection

    timestamps(type: :utc_datetime)
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :color])
    |> validate_required([:name])
    |> maybe_generate_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase alphanumeric with dashes"
    )
    |> unique_constraint([:collection_id, :slug],
      error_key: :name,
      message: "a tag with this name already exists in this collection"
    )
  end

  defp maybe_generate_slug(changeset) do
    case get_field(changeset, :slug) do
      nil -> put_change(changeset, :slug, slugify(get_field(changeset, :name)))
      "" -> put_change(changeset, :slug, slugify(get_field(changeset, :name)))
      _existing -> changeset
    end
  end

  defp slugify(nil), do: ""

  defp slugify(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/, "")
    |> String.replace(~r/[\s_]+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end
end
