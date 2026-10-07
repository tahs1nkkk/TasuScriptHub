# Feature memory: godmode

State: `Godmode`.

Behavior: current controller performs local humanoid reset/rebinding behavior and tracks replacement state.

Rework: document the exact executor/game limitations, isolate irreversible game-specific behavior, and guarantee UI does not claim success when the game rejects it.

Executor checks: enable, damage, death, respawn, disable, game rejection, repeated execution, and unload.

Main UI revision 2: the existing toggle is exposed under `Misc`; the view makes no success claim and owns no humanoid mutation. Verify rejection and refresh remain truthful.
