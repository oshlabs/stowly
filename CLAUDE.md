# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Stowly is a Phoenix 1.8 JSON API application (no HTML/LiveView, no dashboard, no mailer) backed by PostgreSQL. It was generated with `mix phx.new stowly --no-html --no-dashboard --no-mailer`.

## Common commands

- `mix setup` — install deps, create DB, run migrations, build assets
- `mix phx.server` or `iex -S mix phx.server` — start the dev server (localhost:4000)
- `mix test` — run all tests (auto-creates/migrates the test DB)
- `mix test test/path/to/test.exs` — run a single test file
- `mix test --failed` — re-run previously failed tests
- `mix precommit` — compile (warnings-as-errors), unlock unused deps, format, and test. **Run this before committing.**
- `mix ecto.gen.migration migration_name` — generate a new migration (always use this, never create migration files manually)
- `mix ecto.migrate` / `mix ecto.rollback` — run/rollback migrations
- `mix format` — format code

## Architecture

- **`lib/stowly/`** — business logic (contexts). `Stowly.Repo` is the Ecto repo (Postgres).
- **`lib/stowly_web/`** — web layer. `StowlyWeb.Router` defines an `/api` scope piped through the `:api` pipeline (JSON only). `StowlyWeb.Endpoint` is the Bandit-based HTTP endpoint.
- **`lib/stowly_web.ex`** — macros for `use StowlyWeb, :controller`, `:router`, `:channel`. Contains verified routes config.
- **`config/`** — `config.exs` (shared), `dev.exs`, `test.exs`, `prod.exs`, `runtime.exs` (prod secrets via env vars).
- **`assets/`** — JS (esbuild) and CSS (Tailwind v4). CSS uses `@import "tailwindcss" source(none)` syntax — maintain this format.

## Key conventions (from AGENTS.md)

- Use `Req` for HTTP requests (already available as `:req`). Do not add HTTPoison, Tesla, or :httpc.
- Use `<.icon name="hero-x-mark">` for heroicons — never use `Heroicons` modules.
- Tailwind v4: no `tailwind.config.js`. Config lives in `assets/css/app.css` with `@import`/`@source`/`@plugin` directives.
- Never use `@apply` in CSS.
- All JS/CSS must go through `app.js`/`app.css` bundles — no external script/link tags or inline `<script>` in templates.
- Ecto schemas use `:string` type even for text columns. Use `Ecto.Changeset.get_field/2` to access changeset fields.
- Fields set programmatically (e.g. `user_id`) must not appear in `cast` calls.
- Never nest multiple modules in the same file.
- Predicate functions end with `?` (not `is_` prefix, which is reserved for guards).
- In tests: use `start_supervised!/1` for processes, `Process.monitor/1` instead of `Process.sleep/1`.
