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
- `scripts/main_menu.md`
- `scripts/player_service.md`
- `scripts/mm2.md`
- `scripts/mm2_service.md`

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

The loader design is user-approved and closed apart from cold-start reliability. Critical sounds, the loader mark, the two base rail icons, and remote runtime sources now resolve before ready-state release; missing assets stay hidden/silent. Game-catalog revision 11 and all game windows allow unrestricted offscreen dragging and recenter only when less than 50% remains visible at reopen. Main-menu revision 2 remains on the lower base action. MM2 revision 4 separates its three-page shared-theme view from `mm2_service.lua`, which owns role chams/glow, overlay priority, cards, shooting, gun pickup/drop, and underground farm lifecycle. Bytecode compilation is complete; executor and visual acceptance are still required before merging to `main`.
