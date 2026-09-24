# Feature memory: fullbright and fog removal

State: `Fullbright`, `NoFog`.

Behavior: overrides lighting brightness/ambient/shadows and fog distances.

Rework: preserve exact original properties, compose with lighting modes predictably, and avoid recreating effects every frame.

Executor checks: each toggle alone/together, game property changes, lighting mode switch, repeated load, disable, and unload restoration.

