# Script memory: mm2_service.lua

Role: version-3 MM2 feature engine. It owns role resolution, chams/pulse/cards, overlay claims, gun-drop/pickup, shooting, Auto Fire, and underground farm state. It constructs feature overlays but never a feature window.

Contract: loader compiles the remote module before ready state and exposes a narrow `CreateService` factory through `GetGameUIContext("mm2")`. The controller exposes `GetState`, `SetState`, `Subscribe`, `GetRoleSnapshot`, `PickupGun`, `ShootNow`, `InspectRuntime`, `StartFarm`, `StopFarm`, and `Destroy`.

Ownership: one Heartbeat updates role overlays, pulse, gun drop, pickup, and Auto Fire. One farm revision owns underground movement and touch attempts. Player removal and destroy release overlay claims and destroy only service-owned Highlight/Billboard/Viewport instances. Farm stop/destroy restores saved collision/query/touch, AutoRotate, velocity, and original character pivot.

Capabilities: shooting first equips Gun and activates the game's own Tool controller. When executor metamethod capabilities exist, a lifecycle-owned short-lived namecall redirect changes only argument two of the game's actual `ShootGun:InvokeServer(...)` call to the predicted murderer position; the guessed three-argument invocation remains compatibility fallback only. Auto Fire still requires viewport and raycast visibility. `InspectRuntime` reports resolved Gun/remote/map/container/bag paths and, only when the executor exposes `decompile`, returns bounded `ShootGun` reference snippets for live contract diagnosis. The hook is restored on destroy when still owned by this service.

Farm requires executor `firetouchinterest`. The hot path no longer traverses all of Workspace or PlayerGui: it caches the active map, its `CoinContainer`, and the bag label, enumerates only direct container children, rate-limits rediscovery, and temporarily skips failed collectibles so one invalid coin cannot pin the route. The target part is the BasePart that actually owns the collectible's `TouchTransmitter`, not an arbitrary visual descendant. Movement updates at 30 Hz, touch is double-pulsed, acknowledgement is bounded to roughly 0.2 seconds, and five failures refresh the discovery cache. No Studio substitute or surface fallback exists.

Revision 3 supersedes the configurable revision-2 offset: underground movement is fixed at exactly `7 studs`; UI/config writes cannot change it and the obsolete slider is removed. Bag capacity is parsed from the scoped CoinBags UI when exposed and otherwise defaults to 50. Full bag restores farm-owned character state, resets the character, waits AFK through destruction of the current map/zero-collectible round gap, and resumes only after a different active map has collectibles and the bag is no longer full. Role ESP work is limited to 20 Hz instead of every render Heartbeat. Runtime inspection reports the resolved bag capacity and fixed offset.

GunDrop discovery no longer traverses all Workspace descendants every 0.15 seconds. It is disabled when neither GunDrop ESP nor Auto Pickup needs it, caches a live result, and rate-limits a missing-result rescan to 0.75 seconds; manual pickup may request one forced refresh.

Role cards now use a 40%-smaller Billboard with reduced inner padding. Weapon viewport geometry rotates 90° right; missing equipped skin geometry falls back to a cached role-appropriate default weapon found in ReplicatedStorage.

Executor checks: all three roles and rapid role changes; cards separately/together; weapon skins; general-ESP priority; manual and automatic shooting with/without visibility/Gun/remote; inspect the live remote/decompile report; confirm game-owned shot observation rather than fallback status; gun pickup/drop; map/lobby/round transitions; variable bag HUD; collectible cycling and failed-target skip; sustained farm frame time; death/respawn; stop; unload/hook restoration; and re-execution migration.

Premium revision 1 removes the service-private role palette at runtime. `DataColors` arrives through loader service context; Murderer is red, Sheriff blue, and Innocent green for fill/outline and matching view text.
