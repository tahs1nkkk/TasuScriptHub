# Feature memory: orbit and avatar modes

State: `Orbit`, `OrbitMode`, `OrbitRadius`, `OrbitSpeed`, `OrbitHeight`, `OrbitOffset`; uses selected player.

Behavior: circle, wave, vertical/horizontal loop, spiral, avatar spin, carpet, backpack, and helicopter transforms.

Rework: mode strategies share one time source and cleanup contract; player selection comes from the player directory service.

Executor checks: every mode, parameter limits, target move/leave/die, local respawn, select change, disable, and unload.

