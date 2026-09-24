# System memory: keybinds

Current behavior allows selected toggles/actions to capture and react to user keybinds stored in `State.Keybinds`.

Rework requirements: stable action IDs, one input router, conflict detection, processed-input and text-focus guards, visible unbind/reset, config serialization, and automatic removal when a feature unregisters.

The keybind editor uses shared modal/control/theme components. A feature never creates its own input listener merely to support a bind.

Executor checks: assign, replace, conflict, unbind, save/load, typing/chat focus, feature removal, respawn, double load, and unload.

