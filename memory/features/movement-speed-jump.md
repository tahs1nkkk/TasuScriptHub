# Feature memory: speed and jump power

State: `Speed`, `SpeedMethod`, `SpeedValue`, `Jump`, `JumpValue`.

Behavior: applies WalkSpeed, velocity, or CFrame movement and custom jump power.

Rework: controller records original humanoid values, validates method/range, and restores on disable, death, character change, and unload.

Executor checks: every method, moving/stationary, slopes, seated state, respawn, conflicting game scripts, disable, and unload.

Main UI revision 1: speed/jump controls are reconstructed in `Hareket`. Verify conditional rows, hotkey refresh, and restoration after closing/unloading the view.
