defmodule Stowly.Repo.Migrations.AddSearchIndex do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", "DROP EXTENSION IF EXISTS pg_trgm"

    alter table(:items) do
      add :search_vector, :tsvector
    end

    execute """
            CREATE OR REPLACE FUNCTION items_search_vector_trigger() RETURNS trigger AS $$
            BEGIN
              NEW.search_vector :=
                setweight(to_tsvector('english', coalesce(NEW.name, '')), 'A') ||
                setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
                setweight(to_tsvector('english', coalesce(NEW.notes, '')), 'C') ||
                setweight(to_tsvector('english', coalesce(NEW.barcode, '')), 'C');
              RETURN NEW;
            END
            $$ LANGUAGE plpgsql;
            """,
            "DROP FUNCTION IF EXISTS items_search_vector_trigger();"

    execute """
            CREATE TRIGGER items_search_vector_update
            BEFORE INSERT OR UPDATE ON items
            FOR EACH ROW EXECUTE FUNCTION items_search_vector_trigger();
            """,
            "DROP TRIGGER IF EXISTS items_search_vector_update ON items;"

    # Update existing rows
    execute "UPDATE items SET search_vector = NULL WHERE TRUE;", ""

    create index(:items, [:search_vector], using: :gin)
  end
end
