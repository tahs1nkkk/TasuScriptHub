# Script memory: mm2.lua

Role: shared-theme Murder Mystery 2 game-window view and controller adapter.

Current shape: `mm2.lua` owns no gameplay loop. It requests `mm2_service.lua` from the loader context, mounts one `MM2GameRoot`, and exposes three pages (`ESP`, `AIM`, `FARM`) through the smaller shared game-window contract. It returns the controller and publishes `env.TasuHubMM2` for compatibility.

Controller contract: `GetState`, `SetState`, `Enable`, `Disable`, `RefreshCharacter`, `Open`, `Close`, `Toggle`, `IsOpen`, `Destroy`, and `Unload`. The loader owns catalog execution, controller registration, the square game-icon rail button, automatic first open, and hub-level destruction. MM2 owns only its feature runtime and smaller 620×420 responsive view.

Revision-4 UI: the 56 px header stretches the official banner without crop, simulates soft blur with clipped offset samples, and applies a `Base` tint. Header/footer drag is unrestricted; reopening recenters only below 50% visible area. The fixed mini-navigation collapses from 138 to 58 px without reflow jitter. Page replacement is exit → 0.22-second gap → entry. Controls are English and use only the shared component language.

The view consumes service snapshots and calls `SetState`, `ShootNow`, `PickupGun`, `StartFarm`, and `StopFarm`; footer feedback comes only from the service subscription. Re-execution snapshots the prior controller before unload so legacy `PlayerESP=true` migrates to Murderer/Sheriff enabled and Innocent disabled.

Do not assume remote names or events remain stable. Role resolution and gun/action discovery must fail safely and report unsupported game state. Direct standalone execution without a live shared TasuHub context is intentionally rejected; supported execution is the executor-loaded catalog path.

Runtime validation follows `../EXECUTOR_TESTING.md`; MM2 checks live under `../features/mm2-*`.

Premium revision 1 registers every MM2 toggle plus Shoot Now/Pick Up Gun with the central Bind Manager. Stable IDs use the `mm2.*` namespace, action cooldowns are 0.75/1.0 seconds, icons are semantic manifest keys, and all registrations are removed during controller destroy. Role labels and HUD metadata consume centralized red/blue/green `DataColors`.
