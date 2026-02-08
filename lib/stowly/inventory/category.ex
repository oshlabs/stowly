defmodule Stowly.Inventory.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :color, :string
    field :position, :integer, default: 0

    belongs_to :collection, Stowly.Inventory.Collection
    belongs_to :parent, Stowly.Inventory.Category
    has_many :children, Stowly.Inventory.Category, foreign_key: :parent_id

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :color, :position, :parent_id])
    |> validate_required([:name])
    |> maybe_generate_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase alphanumeric with dashes"
    )
    |> unique_constraint([:collection_id, :slug],
      error_key: :name,
      message: "a category with this name already exists in this collection"
    )
    |> foreign_key_constraint(:parent_id)
  end

  defp maybe_generate_slug(changeset) do
    if get_change(changeset, :name) || get_field(changeset, :slug) in [nil, ""] do
      put_change(changeset, :slug, slugify(get_field(changeset, :name)))
    else
      changeset
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
