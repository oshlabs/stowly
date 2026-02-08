defmodule Stowly.Inventory.CustomFieldDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  @field_types ~w(text number decimal url date boolean select multi_select email)

  schema "custom_field_definitions" do
    field :name, :string
    field :slug, :string
    field :field_type, :string, default: "text"
    field :options, :map, default: %{}
    field :required, :boolean, default: false
    field :position, :integer, default: 0

    belongs_to :collection, Stowly.Inventory.Collection

    timestamps(type: :utc_datetime)
  end

  def field_types, do: @field_types

  def changeset(field_def, attrs) do
    field_def
    |> cast(attrs, [:name, :field_type, :options, :required, :position])
    |> validate_required([:name, :field_type])
    |> validate_inclusion(:field_type, @field_types)
    |> maybe_generate_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase alphanumeric with dashes"
    )
    |> unique_constraint([:collection_id, :slug],
      error_key: :name,
      message: "a custom field with this name already exists in this collection"
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
