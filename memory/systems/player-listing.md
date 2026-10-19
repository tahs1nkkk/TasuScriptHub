# System memory: player listing

Keep the user flow: live join/leave updates, username/display-name search, sorting, view, teleport, Walk/Stop, and fling actions.

Rework requirements: one player data service owns character/health/distance/avatar metadata; UI rows are virtualized or updated only when data changes; action availability is explicit; camera/view state restores on deselection and unload.

Main UI revision 2 uses the dedicated remote `player_service.lua` engine. The Players page is full width, recycles twelve rows around the viewport, and shows avatar, display/username, teammate state, distance, health, View, TP, Fling, and Walk/Stop. Actions are state-aware icon-only controls resolved by the central loader icon registry. Search and sort are view state; metadata/actions remain service owned.

Walk is distinct from TP. One session uses Roblox navmesh paths, humanoid waypoints, three-stud moving-target recomputation, blocked-path recomputation, a 3.5-second leg refresh ceiling, and an atomically replaced Beam route. Arrival stops the session automatically. Stop, TP, Fling, target leave/death, local character loss, replacement, and unload invalidate the revision and clear the route.

Targeted Fling hides the local avatar locally and locks the camera while 36 fixed strongest-profile predictive contact pulses occur, periodically restores the safe root during the run, and unconditionally restores camera, local transparency, humanoid, root/velocities, and conflicting movement state at completion. Anchored/dead/missing targets are rejected. Network ownership may still prevent the target result and is reported as an executor/game limitation, not hidden by the UI.

No row may own a heartbeat connection. The view uses shared list-row, button, icon, and empty-state components.

Executor checks: join/leave, respawn, search, every sort mode, view restore, teleport with missing root, Walk/Stop, moving/blocked/no-route targets, path replacement/cleanup, anchored/dead target rejection, low-ownership fling, movement-system suspension/restore, camera/CFrame/velocity restore, and unload.
