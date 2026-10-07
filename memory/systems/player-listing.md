# System memory: player listing

Keep the user flow: live join/leave updates, username/display-name search, sorting, view, teleport, Walk/Stop, and fling actions.

Rework requirements: one player data service owns character/health/distance/avatar metadata; UI rows are virtualized or updated only when data changes; action availability is explicit; camera/view state restores on deselection and unload.

Main UI revision 2 uses the dedicated remote `player_service.lua` engine. The Players page is full width, recycles twelve rows around the viewport, and shows avatar, display/username, teammate state, distance, health, View, TP, Fling, and Walk/Stop. Search and sort are view state; metadata/actions remain service owned.

Walk is distinct from TP. One session uses Roblox navmesh paths, humanoid waypoints, moving-target and obstruction recomputation, and an atomically replaced Beam route. Stop, TP, Fling, target leave/death, local character loss, replacement, and unload invalidate the revision and clear the route.

Targeted Fling locks the local camera while brief physical contact pulses occur, restores the local root/velocities after every pulse, and restores camera/humanoid/conflicting movement state at completion. Anchored/dead/missing targets are rejected. Network ownership may still prevent the target result and is reported as an executor/game limitation, not hidden by the UI.

No row may own a heartbeat connection. The view uses shared list-row, button, icon, and empty-state components.

Executor checks: join/leave, respawn, search, every sort mode, view restore, teleport with missing root, Walk/Stop, moving/blocked/no-route targets, path replacement/cleanup, anchored/dead target rejection, low-ownership fling, movement-system suspension/restore, camera/CFrame/velocity restore, and unload.
