# Feature memory: MM2 gun-drop ESP

State: MM2 `Enabled`, `GunDropESP`.

Behavior: discovers `GunDrop` descendants and highlights the current drop.

Rework: event-driven discovery with bounded fallback scan, safe replacement/destruction, and explicit unsupported-map state.

Executor checks: no drop, spawn/despawn, nested model/part, multiple candidates, round transition, disable, and unload.

