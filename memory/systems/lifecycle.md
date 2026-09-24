# System memory: lifecycle and unload

Every connection, instance, render-step binding, context action, tween, temporary camera state, character mutation, and executor-global export needs a single owner and cleanup path.

The second canonical execution must unload the first instance before creating the next one. Cleanup is idempotent and safe after partial initialization.

Feature controllers register resources by feature ID. UI overlays and animations register separately from gameplay behavior.

Executor checks: double load, unload during animation, unload with every feature enabled, respawn during enable/disable, and unload after a partial remote-module failure.

