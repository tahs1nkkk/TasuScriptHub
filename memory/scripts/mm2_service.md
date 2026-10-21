# Script memory: mm2_service.lua

Role: version-1 MM2 feature engine. It owns role resolution, chams/pulse/cards, overlay claims, gun-drop/pickup, shooting, Auto Fire, and underground farm state. It constructs feature overlays but never a feature window.

Contract: loader compiles the remote module before ready state and exposes a narrow `CreateService` factory through `GetGameUIContext("mm2")`. The controller exposes `GetState`, `SetState`, `Subscribe`, `GetRoleSnapshot`, `PickupGun`, `ShootNow`, `InspectRuntime`, `StartFarm`, `StopFarm`, and `Destroy`.

Ownership: one Heartbeat updates role overlays, pulse, gun drop, pickup, and Auto Fire. One farm revision owns underground movement and touch attempts. Player removal and destroy release overlay claims and destroy only service-owned Highlight/Billboard/Viewport instances. Farm stop/destroy restores saved collision/query/touch, AutoRotate, velocity, and original character pivot.

Capabilities: shooting first equips Gun and activates the game's own Tool controller. When executor metamethod capabilities exist, a lifecycle-owned short-lived namecall redirect changes only argument two of the game's actual `ShootGun:InvokeServer(...)` call to the predicted murderer position; the guessed three-argument invocation remains compatibility fallback only. Auto Fire still requires viewport and raycast visibility. `InspectRuntime` reports resolved Gun/remote/map/container/bag paths and, only when the executor exposes `decompile`, returns bounded `ShootGun` reference snippets for live contract diagnosis. The hook is restored on destroy when still owned by this service.

Farm requires executor `firetouchinterest`. The hot path no longer traverses all of Workspace or PlayerGui: it caches the active map, its `CoinContainer`, and the bag label, enumerates only direct container children, rate-limits rediscovery, and blacklists failed collectibles for three seconds so one invalid coin cannot pin the route. Movement updates at 30 Hz instead of every Heartbeat, collection acknowledgement is bounded, and five failures refresh the discovery cache instead of permanently stranding the worker. No Studio substitute or surface fallback exists.

Executor checks: all three roles and rapid role changes; cards separately/together; weapon skins; general-ESP priority; manual and automatic shooting with/without visibility/Gun/remote; inspect the live remote/decompile report; confirm game-owned shot observation rather than fallback status; gun pickup/drop; map/lobby/round transitions; variable bag HUD; collectible cycling and failed-target skip; sustained farm frame time; death/respawn; stop; unload/hook restoration; and re-execution migration.

Premium revision 1 removes the service-private role palette at runtime. `DataColors` arrives through loader service context; Murderer is red, Sheriff blue, and Innocent green for fill/outline and matching view text.
