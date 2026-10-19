# Feature memory: off-screen arrows and team colors

State: `Offscreen`, `TeamColors`.

Behavior: computes edge arrows for non-visible targets and optionally derives ESP colors from team identity. Arrow size is inverse to target distance and clamped to 18–42 px (text 16–36 px), so nearby off-screen players are larger without unbounded scaling.

Rework: use safe viewport bounds and inset handling, stable arrow rotation, and a single color-resolution service.

Executor checks: every screen edge, target behind camera, no team, neutral players, team change, tiny viewport, and maximum distance.

Main UI revision 2: offscreen/team controls are exposed through `Visuals` descriptors. Verify state survives close/reopen.
