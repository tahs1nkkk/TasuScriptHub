# Feature memory: freecam

State: `Freecam`, `FreecamSpeed`; includes teleport-player-to-freecam action.

Behavior: detaches camera, sinks movement, freezes/restores character state, and optionally moves the player to camera position.

Rework: one camera controller with explicit enter/exit snapshots, input priority, safe teleport checks, and interruption recovery.

Executor checks: movement/look, speed, character freeze, teleport action, respawn, camera replacement, UI input, disable, and unload.

Main UI revision 2: toggle/speed/action retain stable flags. Speed is validated at `0.2–50` in the UI descriptor, setter, and config-load migration. Verify old configs above/below range, maximum-speed movement, UI focus guards, action activation, and close/reopen without implicit disable.

Improvement pass: mouse look multiplies the captured Roblox user sensitivity instead of replacing it with a fixed feel. Teleport-to-freecam now exits freecam first, releases frozen input/character ownership, places and faces the root directly, zeros assembly velocity, restores humanoid/camera state, and does not leave an airborne glide.

Current tuning: the captured Roblox sensitivity multiplier is `0.009`, twice the preceding `0.0045` coefficient. Executor validation must compare low/default/high Roblox sensitivity and confirm UI pointer focus still blocks camera look.
