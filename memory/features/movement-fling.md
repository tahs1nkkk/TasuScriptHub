# Feature memory: fling

State: `Fling`, `FlingMode`, `FlingPower`, `FlingFlySpeed`.

Behavior: walk, contact, or fly fling modes pulse local assembly motion while attempting to restore player position.

Rework: explicit target/session ownership, bounded physics values, anti-fling priority, guaranteed velocity reset, and clear unsupported-state reporting.

Executor checks: every mode, no target, target leave/death, local respawn, anti-fling interaction, fly controls, disable, and unload.

