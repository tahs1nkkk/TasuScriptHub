# Feature memory: waypoints

State: `Waypoints`; transient selected waypoint index.

Behavior: save current CFrame, select, teleport, delete, and bind actions.

Rework: stable waypoint IDs, validated names/transforms, config serialization, shared list/modal components, and safe missing-root handling.

Executor checks: empty list, add/select/teleport/delete, duplicate names, malformed config data, respawn, binds, and unload.

Main UI revision 2: the registered selector is exposed under `Misc` through the shared dropdown; save/teleport/delete action migration remains pending because those compatibility records do not expose callbacks. Engine/config state is unchanged.
