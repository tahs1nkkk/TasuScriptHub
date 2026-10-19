# Script memory: player_service.lua

Status: version-1 executor-only feature engine loaded remotely by `loader.lua`. It owns player metadata sampling and player actions; it never constructs a feature window.

## Contract

- `Create(context)` requires Players, LocalPlayer, Workspace, RunService, and PathfindingService.
- Public methods are `GetSnapshot`, `Subscribe`, `View`, `Teleport`, `Walk`, `StopWalk`, `Fling`, and `Destroy`.
- Snapshots contain stable user identity, Roblox avatar thumbnail, display/username, teammate relation, distance, health ratio, alive/view/walk state, and action-busy state. One 0.2-second shared heartbeat notifies subscribers; individual rows never own heartbeat connections.
- Only one Walk session may exist. Starting another replaces it; pressing Walk on the active target stops it. Teleport or Fling also stops Walk.
- Walk uses `PathfindingService:CreatePath`, humanoid waypoints, jump actions, target-motion/blocked-path recomputation, and a revision token. It recomputes when the target moves at least three studs or the current leg exceeds 3.5 seconds, and automatically stops on arrival. Its Beam route is atomically replaced after a successful compute and removed on Stop, arrival, missing/dead character, player removal, destroy, or replacement.
- View toggles the camera subject between the target humanoid and local humanoid. Teleport is a separate explicit action.
- Targeted Fling rejects local, missing, dead, anchored, or busy targets. It snapshots local CFrame, linear/angular velocity, AutoRotate, PlatformStand, local-part transparency, and camera type/subject/CFrame. It hides the local avatar only on the local client, locks the camera in Scriptable mode, applies 36 fixed maximum-profile predictive contact pulses, periodically returns to the safe transform, and unconditionally restores every snapshot. Loader callbacks temporarily suspend and then restore fly, orbit, legacy fling, static anti-fling, and moving anti-fling state. Roblox network ownership can still prevent target movement; this is never reported as guaranteed success.
- `Destroy` is idempotent, invalidates action/walk revisions, removes the route, clears subscribers, disconnects service connections, and restores a stale camera subject when possible.

## Executor validation

Required: join/leave, respawn, every sort mode, search, View/restore, TP, Walk/Stop, moving target, blocked/no route, Beam replacement, target death/removal, local death, anchored target rejection, fling during fly/orbit/anti-fling, low ownership, camera/root/velocity restoration, reload, and unload. Roblox Studio is not a supported target.
