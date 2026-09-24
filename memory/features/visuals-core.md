# Feature memory: Visuals core

State: `Visuals.Enabled`, `MaxDistance`, `Thickness`.

Behavior: owns per-player ESP records and render/update cleanup.

Rework: one record lifecycle per player/character, bounded update frequency for text, and explicit renderer ownership. Feature overlays are separate from application UI.

Executor checks: enable/disable, join/leave, respawn, distance boundary, camera replacement, repeated execution, and unload.

