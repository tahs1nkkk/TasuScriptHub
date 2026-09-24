# System memory: config storage

Current behavior saves and loads executor files when file APIs exist and migrates older fields.

Rework requirements: version every payload; whitelist serializable state; isolate migrations; validate ranges/enums; apply state through controllers; never persist transient instances, selected players, active tweens, or runtime handles.

Executor checks: no file API, first save, overwrite confirmation, malformed JSON, old schema migration, partial config, delete/unload boundaries, and reloading active features.

