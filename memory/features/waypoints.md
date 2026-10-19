# Feature memory: waypoints

State: `Waypoints[experienceId]`; transient selected waypoint index. `experienceId` is `game.GameId`, falling back to `game.PlaceId`.

Behavior: save current CFrame, select, teleport, delete, and bind actions.

Rework: stable waypoint IDs, validated names/transforms, config serialization, shared list/modal components, and safe missing-root handling.

Executor checks: empty list, add/select/teleport/delete, duplicate names, malformed config data, respawn, binds, and unload.

Main UI revision 2: Waypoints is a dedicated main category. The shared dropdown and executable Save/Teleport/Delete action descriptors all operate only on the current experience list. Config loading migrates a legacy flat waypoint array into the current experience key; different games no longer share one list.
