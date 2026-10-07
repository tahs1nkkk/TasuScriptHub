# Feature memory: Aim core

State: `Aim.Enabled`, `Aim.Activation`, `Aim.Method`, `Aim.Rage`, `Aim.Smoothing`.

Behavior: selects a valid target during render updates and applies camera or mouse movement according to activation and rage rules.

Rework: controller owns targeting cadence and input state; UI only edits validated state. `HoldRightMouse` is migration-only.

Executor checks: all activation modes, camera/mouse methods, enable/disable, lost focus, respawn, double load, and unload restoration.

Main UI revision 2: existing controls remain stable Aim descriptors under `Aim`; the two-column/collapsible view calls controller `Get`/`Set` only. Add hierarchical search, conditional rage visibility, external refresh, and unload-mid-transition to executor coverage.
