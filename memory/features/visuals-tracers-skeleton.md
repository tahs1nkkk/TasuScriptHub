# Feature memory: ESP tracers and skeleton

State: `Tracers`, `Skeleton`, `Thickness`.

Behavior: screen-space lines connect the viewport to player roots and render R6/R15 motor chains.

Rework: cache rig mapping per character, hide invalid projections, and centralize line pooling so toggles do not allocate every frame.

Executor checks: R6/R15, missing limbs, off-screen/behind-camera players, resolution changes, thickness, rapid respawn, and disable cleanup.

