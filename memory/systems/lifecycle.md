# System memory: lifecycle and unload

Every connection, instance, render-step binding, context action, tween, temporary camera state, character mutation, and executor-global export needs a single owner and cleanup path.

The second canonical execution must unload the first instance before creating the next one. Cleanup is idempotent and safe after partial initialization.

Feature controllers register resources by feature ID. UI overlays and animations register separately from gameplay behavior.

The loader's `BlurEffect` is created through `trackInstance`, tweened back to zero during normal exit, explicitly destroyed after that exit, and also covered by global unload cleanup for reloads or partial initialization.

The loader's single ambient `RenderStepped` connection owns both the 22-row halftone loop and the icon breathing/anchor-rock motion. It is registered through `trackConnection`, runs through the full downward/fade exit, is explicitly disconnected once that exit tween completes, and remains covered by global unload if execution is interrupted early.

Transient loader sounds remain tracked instances. Their cleanup delay respects an explicit target duration plus a one-second margin (minimum four seconds), preventing the three-second reverse exit cue from being destroyed before playback completes.

Executor checks: double load, unload during animation, unload with every feature enabled, respawn during enable/disable, and unload after a partial remote-module failure.
