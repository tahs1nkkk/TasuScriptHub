# System memory: lifecycle and unload

Every connection, instance, render-step binding, context action, tween, temporary camera state, character mutation, and executor-global export needs a single owner and cleanup path.

The second canonical execution must unload the first instance before creating the next one. Cleanup is idempotent and safe after partial initialization.

Feature controllers register resources by feature ID. UI overlays and animations register separately from gameplay behavior.

The loader's `BlurEffect` is created through `trackInstance`, tweened back to zero during normal exit, explicitly destroyed after that exit, and also covered by global unload cleanup for reloads or partial initialization.

The loader's single ambient `RenderStepped` connection owns both the 22-row halftone loop and the icon breathing/anchor-rock motion. TasuHub decal resolution runs once in an asynchronous HTTP/file/custom-asset worker and adds no animation connection; it checks image ownership before applying a late result, so unload cannot recreate UI. No fallback instance is owned or cleaned up. The ambient connection remains covered by global unload and is explicitly disconnected once the full downward/fade exit completes.

Transient loader sounds and the exit cue's child `PitchShiftSoundEffect` remain tracked instances. Their cleanup delay respects an explicit target duration plus a one-second margin (minimum four seconds), preventing the stretched three-second soft UI exit cue from being destroyed before playback completes. The exit cue's scheduled start checks loader ownership and visibility before creating sound state, so unload cannot resurrect audio after cleanup.

Executor checks: double load, unload during animation, unload with every feature enabled, respawn during enable/disable, and unload after a partial remote-module failure.
