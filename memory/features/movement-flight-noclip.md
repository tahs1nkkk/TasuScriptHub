# Feature memory: flight and noclip

State: `Fly`, `FlyMethod`, `FlySpeed`, `Noclip`.

Behavior: camera-relative WASD/vertical flight through velocity or CFrame and optional local collision suppression.

Rework: one flight controller, normalized diagonal speed, stable camera replacement, and exact collision restoration using weak ownership maps.

Executor checks: both methods, all directions, diagonal/vertical movement, changing camera, seated/dead state, respawn, disable, and unload.

