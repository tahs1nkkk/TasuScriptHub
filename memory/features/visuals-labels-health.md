# Feature memory: ESP names, distance, and health

State: `Names`, `Distance`, `Health`, `MaxDistance`.

Behavior: billboard labels show selected identity/distance data and a health bar.

Rework: throttle text updates, clamp health safely, support missing humanoids, and keep label contrast independent from the application theme palette.

Executor checks: display names, long names, zero/max health, changing max health, distance updates, out-of-range hiding, and respawn.

