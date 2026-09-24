# Feature ownership index

This map prevents state or behavior from being lost during the rebuild.

| Current state or subsystem | Owning memory |
| --- | --- |
| `Interface.*`, theme bindings, shared components, icons, animation | `THEME_RULES.md` |
| Executor entrypoint and bootstrap | `scripts/loader.md`, `EXECUTOR_TESTING.md` |
| Full-screen loading experience and live progress | `systems/loader-screen.md` |
| Capability globals and fallbacks | `systems/capability-detection.md` |
| Connections, instances, render bindings, unload | `systems/lifecycle.md` |
| `Aim.Enabled`, activation, method, rage, smoothing | `features/aim-core.md` |
| Aim target part, team/wall/alive rules, distance | `features/aim-targeting.md` |
| Aim prediction | `features/aim-prediction.md` |
| Aim FOV and circle | `features/aim-fov.md` |
| `Visuals.Enabled`, distance, thickness, record lifecycle | `features/visuals-core.md` |
| ESP boxes and fill | `features/visuals-boxes.md` |
| ESP names, distance, health | `features/visuals-labels-health.md` |
| ESP tracers and skeleton | `features/visuals-tracers-skeleton.md` |
| ESP chams and head marker | `features/visuals-chams-head.md` |
| ESP off-screen arrows and team colors | `features/visuals-offscreen-team.md` |
| Legacy visual preview decision | `features/visuals-preview.md` |
| Speed, speed method/value, jump power/value | `features/movement-speed-jump.md` |
| Infinite jump and bunny hop | `features/movement-mobility.md` |
| Flight, flight method/speed, noclip | `features/movement-flight-noclip.md` |
| Click teleport | `features/movement-click-teleport.md` |
| Anti-fling | `features/movement-protection.md` |
| Godmode | `features/movement-godmode.md` |
| Fling modes and values | `features/movement-fling.md` |
| Orbit modes and values | `features/movement-orbit.md` |
| Gravity override | `features/movement-gravity.md` |
| Lighting modes and manual controls | `features/world-lighting.md` |
| Fullbright and fog | `features/world-fullbright-fog.md` |
| Flat textures | `features/world-flat-textures.md` |
| Scoped RGB effects | `features/world-rgb.md` |
| Camera FOV and third person | `features/world-camera.md` |
| Freecam and teleport-to-freecam | `features/world-freecam.md` |
| `Players.Sort`, live directory, player actions | `systems/player-listing.md` |
| `Stats.*` | `features/stats-overlay.md` |
| `Keybinds` and bind capture | `systems/keybinds.md` |
| `Catalog`, source/URL execution, built-in MM2 entry | `systems/script-loading.md` |
| `Waypoints` | `features/waypoints.md` |
| Search registration/ranking/navigation | `systems/search-index.md` |
| Config serialization, files, migrations | `systems/config-storage.md` |
| MM2 script lifecycle | `scripts/mm2.md` |
| MM2 role ESP | `features/mm2-role-esp.md` |
| MM2 gun-drop ESP | `features/mm2-gun-drop.md` |
| MM2 pickup/fire automatic and manual actions | `features/mm2-automation.md` |
