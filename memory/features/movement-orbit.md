# Feature memory: orbit and avatar modes

State: `Orbit`, `OrbitMode`, `OrbitRadius`, `OrbitSpeed`, `OrbitHeight`, `OrbitOffset`; uses selected player.

Behavior: circle, wave, vertical/horizontal loop, spiral, avatar spin, carpet, backpack, and helicopter transforms.

Rework: mode strategies share one time source and cleanup contract; player selection comes from the player directory service.

Executor checks: every mode, parameter limits, target move/leave/die, local respawn, select change, disable, and unload.

Main UI revision 2: player selection, mode, toggle, and values are exposed under `Misc` using the shared dropdown. Verify option refresh, target leave, page replacement, and unload.

Improvement pass: the selected-player dropdown is independent of enable state, and radius/speed plus mode-relevant height/offset controls stay visible before Orbit is enabled. Enabling starts immediately with the selected player and prepared values.

Current integration: both the player and mode dropdown host frames carry explicit `CategoryName = Misc` and `CardName = Orbit` metadata before cloning. This prevents the descriptor adapter from classifying them as `Frame/Frame` and guarantees the live player list is exposed in the Orbit card.
