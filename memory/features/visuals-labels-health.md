# Feature memory: ESP names, distance, and health

State: `Names`, `Distance`, `Health`, `MaxDistance`.

Behavior: billboard labels show selected identity/distance data. Health uses a screen-space track fixed to the current body box edge and exact projected box height, so size follows player distance instead of viewport size.

Rework: throttle text updates, clamp health safely, support missing humanoids, and keep label contrast independent from the application theme palette.

Executor checks: display names, long names, zero/max health, changing max health, distance updates, out-of-range hiding, and respawn.

Main UI revision 2: names/distance/health controls are descriptor-backed `Visuals` rows. Verify toggles through page, card, and search navigation.
