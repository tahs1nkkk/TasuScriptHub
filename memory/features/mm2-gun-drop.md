# Feature memory: MM2 gun-drop ESP

State: MM2 `Enabled`, `GunDropESP`.

Behavior: discovers `GunDrop` descendants and highlights the current drop.

Rework status: the preserved descendant scan and replacement/destruction behavior is controlled by the shared-theme `Ana Sistem` and `GunDrop ESP` controls. The view owns no scanning loop and creates no independent feature window; the MM2 engine remains the only owner of the gun-drop highlight.

Executor checks: launch from the catalog, verify no drop, spawn/despawn, nested model/part, multiple candidates, round transition, disable, window close/reopen, and hub unload/re-execution. The highlight must remain unique and must never survive disable or unload.
