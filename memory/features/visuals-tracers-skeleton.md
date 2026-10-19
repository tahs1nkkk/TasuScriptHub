# Feature memory: ESP tracers and skeleton

State: `Tracers`, `Skeleton`, `Thickness`.

Behavior: screen-space lines connect the viewport to player roots and render R15 motor chains plus a dedicated fixed R6 body-part map. All ESP projection uses `WorldToViewportPoint` consistently, preventing the GUI-inset vertical drift that grew with distance.

Rework: cache rig mapping per character, hide invalid projections, and centralize line pooling so toggles do not allocate every frame.

Executor checks: R6/R15, missing limbs, off-screen/behind-camera players, resolution changes, thickness, rapid respawn, and disable cleanup.

Main UI revision 2: tracer/skeleton toggles use stable `Visuals` descriptors. Category transitions alone must not allocate renderer records.
