# Feature memory: fullbright and fog removal

State: `Fullbright`, `NoFog`.

Behavior: overrides lighting brightness/ambient/shadows and fog distances. No Fog additionally snapshots and suppresses `Atmosphere` density/haze/glare/offset, applies the rule to newly added Atmosphere descendants, enforces while active, and restores exact values on disable/unload.

Rework: preserve exact original properties, compose with lighting modes predictably, and avoid recreating effects every frame.

Executor checks: each toggle alone/together, game property changes, lighting mode switch, repeated load, disable, and unload restoration.

Main UI revision 2: fullbright/fog toggles are displayed under `Lighting` while stable flags stay unchanged. Verify cross-control refresh and unload.
