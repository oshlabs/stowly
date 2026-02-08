defmodule Stowly.Search do
  @moduledoc """
  Universal search across items, tags, categories, custom field values, and locations.
  """
  import Ecto.Query
  alias Stowly.Repo
  alias Stowly.Inventory.Item

  def search(query_string, opts \\ []) do
    query_string = String.trim(query_string)

    if query_string == "" do
      []
    else
      collection_id = Keyword.get(opts, :collection_id)
      search_items(query_string, collection_id)
    end
  end

  defp search_items(query_string, collection_id) do
    tsquery = to_tsquery(query_string)
    like_pattern = "%#{sanitize_like(query_string)}%"

    base_query =
      from(i in Item,
        left_join: c in assoc(i, :category),
        left_join: t in assoc(i, :tags),
        left_join: sl in assoc(i, :storage_location),
        left_join: cfv in assoc(i, :custom_field_values),
        where:
          fragment("? @@ to_tsquery('english', ?)", i.search_vector, ^tsquery) or
            ilike(i.name, ^like_pattern) or
            ilike(i.description, ^like_pattern) or
            ilike(c.name, ^like_pattern) or
            ilike(t.name, ^like_pattern) or
            ilike(sl.name, ^like_pattern) or
            ilike(cfv.value, ^like_pattern),
        distinct: i.id,
        order_by: [
          desc: fragment("ts_rank(?, to_tsquery('english', ?))", i.search_vector, ^tsquery)
        ],
        preload: [:category, :tags, :storage_location, :collection],
        limit: 50
      )

    base_query =
      if collection_id do
        where(base_query, [i], i.collection_id == ^collection_id)
      else
        base_query
      end

    Repo.all(base_query)
  end

  defp to_tsquery(query_string) do
    query_string
    |> String.split(~r/\s+/, trim: true)
    |> Enum.map(&"#{&1}:*")
    |> Enum.join(" & ")
  end

  defp sanitize_like(string) do
    string
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end
end
