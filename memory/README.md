# TasuHub memory index

This directory is the persistent source of truth for the executor-only UI rework.

## Mandatory project memory

- `THEME_RULES.md` — one shared theme contract for every current and future feature.
- `EXECUTOR_TESTING.md` — the only accepted runtime validation process.
- `ARCHITECTURE.md` — boundaries between bootstrap, feature engines, state, and UI.
- `UI_REWORK_PLAN.md` — atomic migration plan from the legacy UI.
- `DEAD_CODE_AUDIT.md` — confirmed dead, compatibility-only, and pending-removal code.
- `UI_COMPONENT_STATE_SHEET.md` — premium component states and approved mockup geometry.

## Script memory

- `scripts/loader.md`
- `scripts/game_catalog.md`
- `scripts/main_menu.md`
- `scripts/player_service.md`
- `scripts/mm2.md`
- `scripts/mm2_service.md`
- `scripts/ui_runtime.md`
- `scripts/bind_service.md`
- `scripts/config_service.md`

## Retained systems to rework

- `systems/script-loading.md`
- `systems/player-listing.md`
- `systems/search-index.md`
- `systems/config-storage.md`
- `systems/lifecycle.md`
- `systems/capability-detection.md`
- `systems/keybinds.md`
- `systems/loader-screen.md`
- `systems/corner-action-buttons.md`
- `systems/legacy-ui-retirement.md`

## Feature memory

Feature-specific files live under `features/`. Each file records current behavior, state ownership, executor dependencies, rework intent, and runtime checks. Theme decisions never belong in feature files; they always reference `THEME_RULES.md`.

`FEATURE_INDEX.md` maps every current persistent state group and functional subsystem to its owning memory file.

## Current gate

The loader design is user-approved and visually closed. Premium runtime revision 1 adds the shared UI runtime, central five-bind manager/HUD, Config V2, manifest-driven MM2 package metadata, exact-experience Auto-run, `preferences_v2.json`, and durable custom catalog records without changing loader presentation. The action rail is limited to Left/Top/Bottom and defaults near the lower-left area of the bottom edge. Executor and visual acceptance are still required before legacy presentation constructors can be removed or `main` can change.
