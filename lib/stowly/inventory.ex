defmodule Stowly.Inventory do
  @moduledoc """
  The Inventory context manages collections and their contents.
  """
  import Ecto.Query
  alias Stowly.Repo
  alias Stowly.Inventory.Collection
  alias Stowly.Inventory.Category
  alias Stowly.Inventory.Tag
  alias Stowly.Inventory.CustomFieldDefinition
  alias Stowly.Inventory.Item
  alias Stowly.Inventory.CustomFieldValue
  alias Stowly.Inventory.ItemPrice
  alias Stowly.Inventory.StorageLocation
  alias Stowly.Inventory.Medium

  ## Collections

  def list_collections do
    Collection
    |> order_by(asc: :position, asc: :name)
    |> Repo.all()
  end

  def get_collection!(id), do: Repo.get!(Collection, id)

  def get_collection_by_slug!(slug), do: Repo.get_by!(Collection, slug: slug)

  def create_collection(attrs \\ %{}) do
    %Collection{}
    |> Collection.changeset(attrs)
    |> Repo.insert()
  end

  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end

  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  def change_collection(%Collection{} = collection, attrs \\ %{}) do
    Collection.changeset(collection, attrs)
  end

  ## Categories

  def list_categories(%Collection{} = collection) do
    Category
    |> where(collection_id: ^collection.id)
    |> order_by(asc: :position, asc: :name)
    |> Repo.all()
  end

  def list_root_categories(%Collection{} = collection) do
    Category
    |> where([c], c.collection_id == ^collection.id and is_nil(c.parent_id))
    |> order_by(asc: :position, asc: :name)
    |> preload(:children)
    |> Repo.all()
  end

  def get_category!(id), do: Repo.get!(Category, id)

  def create_category(%Collection{} = collection, attrs) do
    %Category{collection_id: collection.id}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  ## Tags

  def list_tags(%Collection{} = collection) do
    Tag
    |> where(collection_id: ^collection.id)
    |> order_by(asc: :name)
    |> Repo.all()
  end

  def get_tag!(id), do: Repo.get!(Tag, id)

  def create_tag(%Collection{} = collection, attrs) do
    %Tag{collection_id: collection.id}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  ## Custom Field Definitions

  def list_custom_field_definitions(%Collection{} = collection) do
    CustomFieldDefinition
    |> where(collection_id: ^collection.id)
    |> order_by(asc: :position, asc: :name)
    |> Repo.all()
  end

  def get_custom_field_definition!(id), do: Repo.get!(CustomFieldDefinition, id)

  def create_custom_field_definition(%Collection{} = collection, attrs) do
    %CustomFieldDefinition{collection_id: collection.id}
    |> CustomFieldDefinition.changeset(attrs)
    |> Repo.insert()
  end

  def update_custom_field_definition(%CustomFieldDefinition{} = field_def, attrs) do
    field_def
    |> CustomFieldDefinition.changeset(attrs)
    |> Repo.update()
  end

  def delete_custom_field_definition(%CustomFieldDefinition{} = field_def) do
    Repo.delete(field_def)
  end

  def change_custom_field_definition(%CustomFieldDefinition{} = field_def, attrs \\ %{}) do
    CustomFieldDefinition.changeset(field_def, attrs)
  end

  ## Items

  def list_items(%Collection{} = collection, opts \\ []) do
    query =
      Item
      |> where(collection_id: ^collection.id)
      |> preload([:category, :tags, :prices, :storage_location])

    query =
      case Keyword.get(opts, :category_id) do
        nil -> query
        id -> where(query, category_id: ^id)
      end

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> where(query, status: ^status)
      end

    query =
      case Keyword.get(opts, :storage_location_id) do
        nil -> query
        id -> where(query, storage_location_id: ^id)
      end

    query =
      case Keyword.get(opts, :tag_filter) do
        nil ->
          query

        :none ->
          where(query, [i], false)

        filter when is_list(filter) ->
          {include_no_tag, tag_ids} = Enum.split_with(filter, &(&1 == :no_tag))
          has_no_tag = include_no_tag != []

          case {has_no_tag, tag_ids} do
            {true, []} ->
              from(i in query,
                left_join: it in "item_tags",
                on: it.item_id == i.id,
                where: is_nil(it.tag_id),
                distinct: true
              )

            {false, tag_ids} ->
              from(i in query,
                join: it in "item_tags",
                on: it.item_id == i.id,
                where: it.tag_id in ^tag_ids,
                distinct: true
              )

            {true, tag_ids} ->
              from(i in query,
                left_join: it in "item_tags",
                on: it.item_id == i.id,
                where: it.tag_id in ^tag_ids or is_nil(it.tag_id),
                distinct: true
              )
          end
      end

    query
    |> order_by(desc: :updated_at)
    |> Repo.all()
  end

  def get_item!(id) do
    Item
    |> Repo.get!(id)
    |> Repo.preload([
      :category,
      :tags,
      :prices,
      :storage_location,
      :media,
      custom_field_values: :custom_field_definition
    ])
  end

  def create_item(%Collection{} = collection, attrs, tag_ids \\ []) do
    tags = if tag_ids == [], do: [], else: Tag |> where([t], t.id in ^tag_ids) |> Repo.all()

    %Item{collection_id: collection.id}
    |> Item.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.insert()
  end

  def update_item(%Item{} = item, attrs, tag_ids \\ nil) do
    changeset = Item.changeset(item, attrs)

    changeset =
      if tag_ids do
        tags = if tag_ids == [], do: [], else: Tag |> where([t], t.id in ^tag_ids) |> Repo.all()
        Ecto.Changeset.put_assoc(changeset, :tags, tags)
      else
        changeset
      end

    Repo.update(changeset)
  end

  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  ## Custom Field Values

  def set_custom_field_values(%Item{} = item, field_values) do
    Repo.transaction(fn ->
      Enum.each(field_values, fn {definition_id, value} ->
        definition_id = to_int(definition_id)

        case Repo.get_by(CustomFieldValue,
               item_id: item.id,
               custom_field_definition_id: definition_id
             ) do
          nil ->
            %CustomFieldValue{item_id: item.id, custom_field_definition_id: definition_id}
            |> CustomFieldValue.changeset(%{value: value})
            |> Repo.insert!()

          existing ->
            existing
            |> CustomFieldValue.changeset(%{value: value})
            |> Repo.update!()
        end
      end)
    end)
  end

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)

  ## Item Prices

  def list_item_prices(%Item{} = item) do
    ItemPrice
    |> where(item_id: ^item.id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  def create_item_price(%Item{} = item, attrs) do
    %ItemPrice{item_id: item.id}
    |> ItemPrice.changeset(attrs)
    |> Repo.insert()
  end

  def update_item_price(%ItemPrice{} = price, attrs) do
    price
    |> ItemPrice.changeset(attrs)
    |> Repo.update()
  end

  def delete_item_price(%ItemPrice{} = price) do
    Repo.delete(price)
  end

  def change_item_price(%ItemPrice{} = price, attrs \\ %{}) do
    ItemPrice.changeset(price, attrs)
  end

  ## Storage Locations

  def list_storage_locations(%Collection{} = collection) do
    StorageLocation
    |> where(collection_id: ^collection.id)
    |> order_by(asc: :position, asc: :name)
    |> Repo.all()
  end

  def list_root_storage_locations(%Collection{} = collection) do
    StorageLocation
    |> where([l], l.collection_id == ^collection.id and is_nil(l.parent_id))
    |> order_by(asc: :position, asc: :name)
    |> preload([:items, children: [:items, children: [:items, children: :items]]])
    |> Repo.all()
  end

  def get_storage_location!(id) do
    StorageLocation
    |> Repo.get!(id)
    |> Repo.preload([:parent, children: :children, items: [:category, :tags]])
  end

  def create_storage_location(%Collection{} = collection, attrs) do
    %StorageLocation{collection_id: collection.id}
    |> StorageLocation.changeset(attrs)
    |> Repo.insert()
  end

  def update_storage_location(%StorageLocation{} = location, attrs) do
    location
    |> StorageLocation.changeset(attrs)
    |> Repo.update()
  end

  def delete_storage_location(%StorageLocation{} = location) do
    Repo.delete(location)
  end

  def change_storage_location(%StorageLocation{} = location, attrs \\ %{}) do
    StorageLocation.changeset(location, attrs)
  end

  def storage_location_breadcrumbs(%StorageLocation{} = location) do
    build_breadcrumbs(location, [])
  end

  defp build_breadcrumbs(%StorageLocation{parent_id: nil} = location, acc) do
    [location | acc]
  end

  defp build_breadcrumbs(%StorageLocation{} = location, acc) do
    parent = Repo.get!(StorageLocation, location.parent_id)
    build_breadcrumbs(parent, [location | acc])
  end

  ## Media

  def list_media(%Item{} = item) do
    Medium
    |> where(item_id: ^item.id)
    |> order_by(asc: :position, asc: :inserted_at)
    |> Repo.all()
  end

  def get_medium!(id), do: Repo.get!(Medium, id)

  def create_medium(%Item{} = item, attrs) do
    %Medium{item_id: item.id}
    |> Medium.changeset(attrs)
    |> Repo.insert()
  end

  def delete_medium(%Medium{} = medium) do
    Stowly.Uploads.delete(medium.file_path)
    Repo.delete(medium)
  end
end
