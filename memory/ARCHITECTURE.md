# Rework architecture

## Layers

1. `loader.lua` — executor bootstrap, versioning, capability detection, remote module loading, fatal error surface, and global unload handoff.
2. Runtime state — defaults, validated mutations, config serialization, and backward-compatible migrations.
3. Feature controllers — gameplay behavior, connections, render bindings, object ownership, cleanup, and executor capability requirements.
4. Shared services — player directory, search index, script catalog, icon registry, notifications, and lifecycle registry.
5. UI shell — navigation, panels, overlays, component library, shared theme, and animation coordinator.
6. Feature views — declarative control registration only; no gameplay loops or private styling.

`game_catalog.lua` owns catalog presentation and virtualized metadata interaction. `main_menu.lua` owns the general window, navigation/search/dropdown/card/player-row/stats-overlay presentation, and view-scoped inputs only. `player_service.lua` owns player metadata sampling, pathfinding/route ownership, camera view, TP, and targeted fling actions without constructing UI. `loader.lua` retains state/descriptors, stats sampling, icon/HTTP resolution, validated module/script execution, game-controller registration, shared contexts, and global lifecycle. `mm2.lua` remains the first migrated game controller/view.

## Contracts

- A feature controller exposes `GetState`, `SetState`, `Enable`, `Disable`, `RefreshCharacter`, and `Destroy` as applicable.
- All connections, instances, actions, and render-step names are registered with lifecycle ownership.
- Search indexes feature metadata and control commands, not raw Roblox instances.
- Player listing consumes a player data service; rows do not poll or own gameplay logic.
- Main descriptors include deterministic registration/section order and presentation category without changing compatibility flags.
- Catalog loading returns structured success/error results and never owns its own visual theme.
- A loaded game script returns a controller; the loader registers its rail action and lifecycle, while the catalog only consumes the returned activation callback.
- UI and feature state communicate through stable IDs, not display labels.
- Main-menu search indexes copied stable descriptors; it never discovers controls by traversing either visible or legacy instances.

## Migration constraint

Feature engines and state remain intact while the legacy presentation is suppressed behind `UI.LegacyUIEnabled = false`. No legacy visual may reappear. Physical removal of the dormant legacy builders happens as their replacement services/components land, without deleting feature controllers or executor APIs.
