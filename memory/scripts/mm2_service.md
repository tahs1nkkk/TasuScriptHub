# Script memory: mm2_service.lua

Role: version-1 MM2 feature engine. It owns role resolution, chams/pulse/cards, overlay claims, gun-drop/pickup, shooting, Auto Fire, and underground farm state. It constructs feature overlays but never a feature window.

Contract: loader compiles the remote module before ready state and exposes a narrow `CreateService` factory through `GetGameUIContext("mm2")`. The controller exposes `GetState`, `SetState`, `Subscribe`, `GetRoleSnapshot`, `PickupGun`, `ShootNow`, `StartFarm`, `StopFarm`, and `Destroy`.

Ownership: one Heartbeat updates role overlays, pulse, gun drop, pickup, and Auto Fire. One farm revision owns underground movement and touch attempts. Player removal and destroy release overlay claims and destroy only service-owned Highlight/Billboard/Viewport instances. Farm stop/destroy restores saved collision/query/touch, AutoRotate, velocity, and original character pivot.

Capabilities: `ShootGun` must be a discovered `RemoteFunction`; Auto Fire requires viewport and raycast visibility and equips Gun before invoking. Farm requires executor `firetouchinterest`, discovers coin/candy/token models dynamically, moves at constant speed below each target, verifies collection, and stops after five consecutive failures. No Studio substitute or surface fallback exists.

Executor checks: all three roles and rapid role changes; cards separately/together; weapon skins; general-ESP priority; manual and automatic shooting with/without visibility/Gun/remote; gun pickup/drop; map/lobby/round transitions; variable bag HUD; collectible success/failure; death/respawn; stop; unload; and re-execution migration.
