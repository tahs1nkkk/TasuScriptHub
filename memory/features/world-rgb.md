# Feature memory: RGB effects

State: `World.RGB.ESP`, `World.RGB.Aim`, `World.RGB.World`, each with enabled/speed/saturation/brightness.

Behavior: produces time-based colors for the three scopes.

Rework: one color service calculates scoped colors; consumers request values without owning loops or palettes. This runtime color effect is separate from application theme selection.

Executor checks: each scope alone/together, parameter limits, toggle, low FPS, reload, and unload.

Main UI revision 2: all three RGB scopes appear under `Lighting` while runtime colors stay outside the UI palette. World RGB changes only `ColorCorrectionEffect.TintColor`: Glow retains its intensity/size/threshold and correction profile, Neon retains its values/profile, Manual retains brightness/contrast/saturation, and Default uses the legacy RGB bloom/correction profile. No view-owned color loop exists.
