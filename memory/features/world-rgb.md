# Feature memory: RGB effects

State: `World.RGB.ESP`, `World.RGB.Aim`, `World.RGB.World`, each with enabled/speed/saturation/brightness.

Behavior: produces time-based colors for the three scopes.

Rework: one color service calculates scoped colors; consumers request values without owning loops or palettes. This runtime color effect is separate from application theme selection.

Executor checks: each scope alone/together, parameter limits, toggle, low FPS, reload, and unload.

