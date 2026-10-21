# Feature memory: MM2 gun-drop ESP

State: MM2 `Enabled`, `GunDropESP`.

Behavior: discovers `GunDrop` descendants and highlights the current drop.

Rework status: descendant scan and replacement/destruction are controlled by the shared-theme `Main System` and `Gun Drop ESP` controls on the ESP page. The view owns no scan; `mm2_service.lua` is the single gun-drop Highlight owner.

Executor checks: launch from the catalog, verify no drop, spawn/despawn, nested model/part, multiple candidates, round transition, disable, window close/reopen, and hub unload/re-execution. The highlight must remain unique and must never survive disable or unload.
