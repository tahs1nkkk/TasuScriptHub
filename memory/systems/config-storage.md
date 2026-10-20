# System memory: config storage

Current behavior saves and loads executor files when file APIs exist and migrates older fields.

Rework requirements: version every payload; whitelist serializable state; isolate migrations; validate ranges/enums; apply state through controllers; never persist transient instances, selected players, active tweens, or runtime handles.

Main UI revision 2 exposes compatible config dropdown, name input, save/load, overwrite, delete, and reset descriptors on `Configs`; visible unload now belongs to the Home hold control. List selection uses the shared real dropdown component. Config loading clamps legacy/current `World.FreecamSpeed` values into `0.2–50`, coerces removed `Always` aim activation to `Right Mouse`, clears removed Godmode/fling-power keys, and migrates the former flat waypoint array below the current experience key. The main window does not read executor files or mutate serialized state directly.

Executor checks: no file API, first save, overwrite confirmation, malformed JSON, old schema migration, partial config, delete/unload boundaries, and reloading active features.

Global UI preferences are intentionally separate from settings configs. `TasuHub/preferences_v1.json` is a version-1 executor file containing only the last theme name and stable catalog favorite IDs. It loads before visible UI composition, ignores incompatible versions/malformed content, and is never deleted on unload. Theme changes and favorite toggles save immediately when file APIs exist. `configPayload` omits `Interface.ThemeName`, config loading ignores legacy embedded theme names, and Reset to Defaults preserves the global preferred theme. This file is extensible for future non-feature preferences but must never contain gameplay settings.
