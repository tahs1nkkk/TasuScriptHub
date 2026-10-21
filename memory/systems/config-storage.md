# System memory: Config V2 and global preferences

`config_service.lua` version 2 owns validated settings configs. UI views call its controller and never read/write files directly.

## Config V2

- Path: `TasuHub/configs/v2/<sanitized-name>.json`.
- Schema/version must be exactly `TasuHub.Config` / `2`; malformed JSON, unsupported schema, non-scalar trees, excessive depth/count, duplicate bind IDs/keys, or more than five binds are rejected before feature state is applied.
- Payload contains hub/schema version, stable `ControlId → value` general settings, game-package state keyed by package ID, ordered binds, config-local Auto-run selection, and experience-keyed waypoints.
- Color values use an explicit validated `Color3` scalar record. Instances, runtime handles, tweens, player selections, popup state, cooldown state, theme, favorites, and window positions are excluded.
- General values are applied through registered control setters. Game values are applied through active controller `SetState`; unavailable game sections produce partial success. Config Auto-run may load the exactly matching current-experience package first, but never mutates global Auto-run preference and never silently replaces a different active package.
- Legacy configs under `configs/` are retained but are neither listed nor read. No V1 config migration exists.

## Global durable data

- `TasuHub/preferences_v2.json` stores only last theme, stable favorite IDs, and one Auto-run entry ID per exact `place:<PlaceId>` or `game:<GameId>` scope.
- A valid `preferences_v1.json` theme/favorite file is read once when v2 is absent, copied to v2, and never deleted.
- `TasuHub/catalog_v2.json` separately persists validated custom HTTPS/source catalog records so a selected custom Auto-run target still exists after re-execution.
- Theme, favorites, and Auto-run save immediately when changed. Normal config load/reset never overwrites global theme/favorites/Auto-run.

Executor checks: save/load/list/delete/reset; no filesystem; malformed JSON; invalid schema; more than five binds; partial game load; current/wrong experience Auto-run; global/config conflict; custom catalog reload; legacy files remaining hidden and untouched.
