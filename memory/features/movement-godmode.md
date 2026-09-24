# Feature memory: godmode

State: `Godmode`.

Behavior: current controller performs local humanoid reset/rebinding behavior and tracks replacement state.

Rework: document the exact executor/game limitations, isolate irreversible game-specific behavior, and guarantee UI does not claim success when the game rejects it.

Executor checks: enable, damage, death, respawn, disable, game rejection, repeated execution, and unload.

