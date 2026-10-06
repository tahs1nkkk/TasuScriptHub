# System memory: config storage

Current behavior saves and loads executor files when file APIs exist and migrates older fields.

Rework requirements: version every payload; whitelist serializable state; isolate migrations; validate ranges/enums; apply state through controllers; never persist transient instances, selected players, active tweens, or runtime handles.

Main UI revision 1 exposes compatible config dropdown, name input, save/load, overwrite, delete, reset, and unload descriptors on the `Configs` category. These controls still call the existing controller callbacks; the main window does not read executor files or mutate serialized state directly. Fixed-theme color controls remain excluded from the main index.

Executor checks: no file API, first save, overwrite confirmation, malformed JSON, old schema migration, partial config, delete/unload boundaries, and reloading active features.
