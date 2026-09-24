# Feature memory: speed and jump power

State: `Speed`, `SpeedMethod`, `SpeedValue`, `Jump`, `JumpValue`.

Behavior: applies WalkSpeed, velocity, or CFrame movement and custom jump power.

Rework: controller records original humanoid values, validates method/range, and restores on disable, death, character change, and unload.

Executor checks: every method, moving/stationary, slopes, seated state, respawn, conflicting game scripts, disable, and unload.

