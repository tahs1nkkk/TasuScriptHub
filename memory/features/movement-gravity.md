# Feature memory: custom gravity

State: `Gravity`, `GravityValue`.

Behavior: overrides client workspace gravity and restores the captured original value.

Rework: lifecycle owner records one baseline and avoids overwriting a newer external change during cleanup without warning.

Executor checks: zero/high values, toggle, game gravity change while active, respawn, repeated load, and unload restoration.

