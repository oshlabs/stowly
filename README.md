# Stowly

A self-hosted home inventory management system built with [Phoenix](https://www.phoenixframework.org/) and [LiveView](https://hexdocs.pm/phoenix_live_view). Organize, categorize, label, and search your collections — from electronics parts to stamps — all from your browser.

Stowly is designed to run on your local network without authentication. It provides a responsive single-page application experience via Phoenix LiveView, so it works equally well on a laptop or phone.

## Features

### Collections

Manage multiple independent collections (e.g. "Electronics", "Stamps", "LEGO"). Each collection has its own items, categories, tags, storage locations, custom fields, and label templates. Collections can be themed with custom colors and background images so they are visually distinct.

### Items

Each item in a collection can have:

- **Name** and **description**
- **Category** (user-defined, with color coding)
- **Tags** (user-defined, with color coding)
- **Storage location** (where the item physically lives)
- **Quantity** tracking
- **Code** (barcode or QR code) — type it, generate one, or scan with your camera
- **Prices** — multiple prices per item, each with a configurable currency, vendor/store, and order quantity
- **Custom fields** — define your own fields (text, number, boolean, date) per collection
- **Photos** — upload or capture images directly from your device camera; stored on disk with metadata in the database

### Storage Locations

Hierarchical storage locations (e.g. Shelf > Box > Drawer > Tray) with:

- Parent/child relationships
- Location types (shelf, box, drawer, tray, cabinet, room, bin, bag, other)
- Optional barcode/QR code per location
- Item counts per location

### Categories & Tags

- User-defined categories and tags per collection
- Color picker with preset palette for quick selection
- Assign categories and multiple tags to items for flexible organization

### Search

Global search across the active collection. Search matches against item names, descriptions, categories, tags, custom field values, codes, and location names. Accessible from a dedicated search page with instant results.

### Label Design & Printing

Design and print labels with QR codes and barcodes directly from the application:

- **Zone-based layout editor** — split a label into up to 3 zones (horizontal or vertical), each containing either a code (QR/barcode) or stacked text fields
- **Preset layouts** — QR + Text, Text + Barcode, Text Only, QR Only, or start from a blank canvas
- **Configurable** — label dimensions (in mm), padding, gap between zones, font sizes (small/medium/large), bold text, horizontal and vertical alignment
- **Live SVG preview** — see the label update in real time as you adjust the layout
- **Target types** — create templates for items or for storage locations
- **Bulk printing** — select multiple items/locations, preview all labels, then print
- **Code generation** — QR codes via [EQRCode](https://hex.pm/packages/eqrcode), barcodes (Code 128) via [Barlix](https://hex.pm/packages/barlix)

### Barcode & QR Scanning

Scan barcodes and QR codes using your device camera. Uses the native [BarcodeDetector API](https://developer.mozilla.org/en-US/docs/Web/API/BarcodeDetector) on supported browsers (Chrome, Edge, Safari) with an automatic [polyfill](https://www.npmjs.com/package/barcode-detector) fallback for Firefox. The scanner shows a real-time video feed with bounding box overlays around detected codes.

### Backup & Restore

- Export the entire database as a `.tgz` archive, optionally including uploaded media files
- Restore from a previously exported backup
- Accessible from the settings page

### Theming

Each collection can have its own visual theme:

- Primary and secondary colors
- Background image
- Applied automatically when viewing the collection

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Elixir ~> 1.15 (tested with 1.19.5 on OTP 28) |
| Web framework | Phoenix 1.8 |
| Real-time UI | Phoenix LiveView 1.0 |
| Database | PostgreSQL via Ecto 3.13 |
| HTTP server | Bandit |
| CSS | Tailwind CSS v4 + DaisyUI |
| JS bundler | esbuild |
| QR codes | EQRCode |
| Barcodes | Barlix (Code 128, Code 39) |
| Icons | Heroicons v2.2 |

## Prerequisites

- **Elixir** >= 1.15 and **Erlang/OTP** >= 26
- **PostgreSQL** >= 14
- **Node.js** is _not_ required (esbuild and Tailwind are managed by Mix)

## Installation

### Development

1. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd stowly
   ```

2. **Configure the database** (optional):

   By default, Stowly connects to PostgreSQL at `localhost` with username `postgres` and password `postgres`. To change this, edit `config/dev.exs`.

3. **Install dependencies, create the database, and build assets:**

   ```bash
   mix setup
   ```

4. **Start the server:**

   ```bash
   mix phx.server
   ```

   Or start it inside an interactive Elixir shell:

   ```bash
   iex -S mix phx.server
   ```

5. **Open your browser** at [http://localhost:4000](http://localhost:4000).

### Production

1. **Set required environment variables:**

   | Variable | Description | Example |
   |----------|-------------|---------|
   | `DATABASE_URL` | PostgreSQL connection string | `ecto://user:pass@host/stowly_prod` |
   | `SECRET_KEY_BASE` | Secret for signing cookies/sessions | Generate with `mix phx.gen.secret` |
   | `PHX_SERVER` | Enable the HTTP server | `true` |
   | `PHX_HOST` | Public hostname | `stowly.local` |

   Optional variables:

   | Variable | Description | Default |
   |----------|-------------|---------|
   | `PORT` | HTTP port | `4000` |
   | `POOL_SIZE` | Database connection pool size | `10` |
   | `ECTO_IPV6` | Enable IPv6 for database connections | `false` |
   | `DNS_CLUSTER_QUERY` | DNS query for clustering | _(none)_ |

2. **Build a release:**

   ```bash
   MIX_ENV=prod mix setup
   MIX_ENV=prod mix assets.deploy
   MIX_ENV=prod mix release
   ```

3. **Run the release:**

   ```bash
   PHX_SERVER=true _build/prod/rel/stowly/bin/stowly start
   ```

4. **Run migrations** (for upgrades):

   ```bash
   _build/prod/rel/stowly/bin/stowly eval "Stowly.Release.migrate()"
   ```

   Or if running from source:

   ```bash
   MIX_ENV=prod mix ecto.migrate
   ```

## Development

### Useful commands

| Command | Description |
|---------|-------------|
| `mix setup` | Install deps, create DB, run migrations, build assets |
| `mix phx.server` | Start the dev server on port 4000 |
| `mix test` | Run the full test suite |
| `mix test test/path/to/file.exs` | Run a single test file |
| `mix test --failed` | Re-run only previously failed tests |
| `mix precommit` | Compile (warnings-as-errors), unlock unused deps, format, and test |
| `mix format` | Format all Elixir source files |
| `mix ecto.gen.migration name` | Generate a new database migration |
| `mix ecto.migrate` | Run pending migrations |
| `mix ecto.rollback` | Roll back the last migration |
| `mix ecto.reset` | Drop, create, and re-migrate the database |

### Project structure

```
lib/
  stowly/                    # Business logic (contexts)
    inventory.ex             # Items, collections, locations, categories, tags
    labels.ex                # Label template rendering (v1 legacy + v2 zone layout)
    search.ex                # Full-text search across items
    media.ex                 # Photo/media management
    backup.ex                # Database export/import
    codes.ex                 # QR code and barcode generation
    labels/
      label_template.ex      # Label template Ecto schema
    inventory/
      collection.ex          # Collection schema
      item.ex                # Item schema
      category.ex            # Category schema
      tag.ex                 # Tag schema
      storage_location.ex    # Storage location schema
      custom_field_*.ex      # Custom field schemas
      item_price.ex          # Price schema
      media.ex               # Media schema
  stowly_web/                # Web layer
    router.ex                # Route definitions
    controllers/
      label_controller.ex    # Label print endpoint
      backup_controller.ex   # Backup download endpoint
    live/
      home_live.ex           # Landing page
      search_live.ex         # Search interface
      settings_live.ex       # App settings
      collection_live/       # Collection CRUD
      item_live/             # Item CRUD
      location_live/         # Storage location CRUD
      label_live/            # Label template editor, preview, print
    components/
      core_components.ex     # Shared UI components
```

### Running tests

```bash
mix test
```

The test database is automatically created and migrated. All 85+ tests should pass. Run `mix precommit` before committing to ensure code compiles without warnings, formatting is correct, and all tests pass.

## License

See [LICENSE](LICENSE) file for details.
