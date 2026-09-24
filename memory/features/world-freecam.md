# Feature memory: freecam

State: `Freecam`, `FreecamSpeed`; includes teleport-player-to-freecam action.

Behavior: detaches camera, sinks movement, freezes/restores character state, and optionally moves the player to camera position.

Rework: one camera controller with explicit enter/exit snapshots, input priority, safe teleport checks, and interruption recovery.

Executor checks: movement/look, speed, character freeze, teleport action, respawn, camera replacement, UI input, disable, and unload.

