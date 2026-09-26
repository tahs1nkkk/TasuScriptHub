# TasuHub memory index

This directory is the persistent source of truth for the executor-only UI rework.

## Mandatory project memory

- `THEME_RULES.md` — one shared theme contract for every current and future feature.
- `EXECUTOR_TESTING.md` — the only accepted runtime validation process.
- `ARCHITECTURE.md` — boundaries between bootstrap, feature engines, state, and UI.
- `UI_REWORK_PLAN.md` — atomic migration plan from the legacy UI.
- `DEAD_CODE_AUDIT.md` — confirmed dead, compatibility-only, and pending-removal code.

## Script memory

- `scripts/loader.md`
- `scripts/game_catalog.md`
- `scripts/mm2.md`

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

The loader design is user-approved and closed after the final ready-text scale revision. Preserve it as a finished shared system unless the user explicitly reopens loader work. The first game-catalog window revision is implemented through the upper corner-action button and remote `game_catalog.lua` module; it is not runtime-ready until its executor checklist is completed and the user approves visual revisions. The general menu launched by the lower button remains the following UI phase.
