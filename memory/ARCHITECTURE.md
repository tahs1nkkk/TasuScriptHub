# Rework architecture

## Layers

1. `loader.lua` — executor bootstrap, versioning, capability detection, remote module loading, fatal error surface, and global unload handoff.
2. Runtime state — defaults, validated mutations, config serialization, and backward-compatible migrations.
3. Feature controllers — gameplay behavior, connections, render bindings, object ownership, cleanup, and executor capability requirements.
4. Shared services — player directory, search index, script catalog, icon registry, notifications, and lifecycle registry.
5. UI shell — navigation, panels, overlays, component library, shared theme, and animation coordinator.
6. Feature views — declarative control registration only; no gameplay loops or private styling.

`game_catalog.lua` owns catalog presentation and virtualized metadata interaction. `main_menu.lua` owns the general window, navigation/search/dropdown/card/player-row/stats-overlay presentation, and view-scoped inputs only. `player_service.lua` owns player metadata sampling, pathfinding/route ownership, camera view, TP, and targeted fling actions without constructing UI. `mm2_service.lua` owns every MM2 feature loop and overlay; `mm2.lua` owns only the shared-theme game-window presentation and controller adapter. `loader.lua` retains state/descriptors, source/audio/icon preloading, validated module execution, overlay arbitration, game-controller registration, shared contexts, and global lifecycle.

Premium runtime revision 1 adds three isolated modules: `ui_runtime.lua` owns shared presentation primitives/scopes, `bind_service.lua` owns the only key router plus right-center HUD/cooldown scheduler, and `config_service.lua` owns Config V2 validation/file transactions. `UI.GamePackages` is the central built-in package manifest. Global preferences, custom catalog records, and feature configs are separate stores: `preferences_v2.json`, `catalog_v2.json`, and `configs/v2/*.json`.

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
- Category and player-action images resolve through loader-owned `CategoryIconUrls` and `MainIconUrls`. The main view receives only resolved-asset getters and live update callbacks.
- Waypoints are stored below one experience key (`game.GameId`, falling back to `game.PlaceId`) and are presented as their own category without changing the saved transform payload shape.
- Unload first drives every active feature flag to its safe disabled state and synchronously restores owned world/character properties. Controller destruction and the global instance/connection sweep happen only after that feature shutdown boundary.
- Player-service exclusive actions suspend both static and moving anti-fling modes and restore the prior modes after the action token ends.
- Global UI preferences are loader-owned and versioned independently from feature configs. Views receive copied getters and narrow setters; no view reads/writes executor files directly.
- The shared `ScreenGui` uses global Z-index ordering: feature overlay GUI remains in the low renderer band and application windows remain in the 2000+ interaction bands.
- Game overlays claim a player through the loader-owned weak claim registry. While a game claim exists, the general ESP renderer hides its record for that player; release is mandatory on disable, death/removal, role loss, and destroy.
- Game views register bind metadata and controller callbacks with `bind_service.lua`; they never create feature key listeners. Config adapters use stable `ControlId`/package IDs and apply values through controllers rather than merging raw state.

## Migration constraint

Feature engines and state remain intact while the legacy presentation is suppressed behind `UI.LegacyUIEnabled = false`. No legacy visual may reappear. Physical removal of the dormant legacy builders happens as their replacement services/components land, without deleting feature controllers or executor APIs.
