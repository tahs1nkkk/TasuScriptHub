# Rework architecture

## Layers

1. `loader.lua` — executor bootstrap, versioning, capability detection, remote module loading, fatal error surface, and global unload handoff.
2. Runtime state — defaults, validated mutations, config serialization, and backward-compatible migrations.
3. Feature controllers — gameplay behavior, connections, render bindings, object ownership, cleanup, and executor capability requirements.
4. Shared services — player directory, search index, script catalog, icon registry, notifications, and lifecycle registry.
5. UI shell — navigation, panels, overlays, component library, shared theme, and animation coordinator.
6. Feature views — declarative control registration only; no gameplay loops or private styling.

`game_catalog.lua` owns catalog presentation, immutable metadata filtering/sorting, session-only favorite/filter state, internal drawer/card interaction, nine-card virtualization, active-page cover caching, and popup transition state only. `main_menu.lua` owns the general window shell, category/search presentation, one selected descriptor page, and view-scoped control input only; it consumes loader callbacks and cannot own gameplay state or loops. `loader.lua` retains catalog/control data, stable descriptor production, shared geometry tokens, HTTP/custom-asset resolution, validated script execution, game-controller registration, dynamic rail actions, shared contexts, and global lifecycle handoff. `mm2.lua` is the first migrated game feature controller/view: it retains its engine and cleanup, consumes only the shared context, mounts below `InterfaceRoot`, and returns its controller rather than creating a separate `ScreenGui`.

## Contracts

- A feature controller exposes `GetState`, `SetState`, `Enable`, `Disable`, `RefreshCharacter`, and `Destroy` as applicable.
- All connections, instances, actions, and render-step names are registered with lifecycle ownership.
- Search indexes feature metadata and control commands, not raw Roblox instances.
- Player listing consumes a player data service; rows do not poll or own gameplay logic.
- Catalog loading returns structured success/error results and never owns its own visual theme.
- A loaded game script returns a controller; the loader registers its rail action and lifecycle, while the catalog only consumes the returned activation callback.
- UI and feature state communicate through stable IDs, not display labels.
- Main-menu search indexes copied stable descriptors; it never discovers controls by traversing either visible or legacy instances.

## Migration constraint

Feature engines and state remain intact while the legacy presentation is suppressed behind `UI.LegacyUIEnabled = false`. No legacy visual may reappear. Physical removal of the dormant legacy builders happens as their replacement services/components land, without deleting feature controllers or executor APIs.
