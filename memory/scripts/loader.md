# Script memory: loader.lua

Role: canonical executor entrypoint and current monolithic TasuHub runtime.

Current responsibilities include defaults/state, capability detection, lifecycle tracking, hidden compatibility UI, descriptors, catalog/configs, feature engines, statistics sampling, remote module composition, and unload.

Implemented rework step: the old card/radial loader was replaced with the approved translucent dark loader. `loader.lua` owns the 392 px TasuHub asset pipeline, staged entry, ambient icon/grid motion, 30 runtime-bound checkpoints, English status text, tracked blur, and whole-background downward/fade exit.

Current presentation state: `UI.LegacyUIEnabled` is permanently false during the rebuild. The legacy top bar, content window, search, preview, stats, toast, modal entrypoints, and unload screen cannot become visible. Feature engines, state, flags, lifecycle, and executor APIs remain loaded. After the loader is destroyed, the new `InterfaceRoot` reveals two identical 70 px base buttons in a four-edge dock plus its silent visibility bar. The upper slot toggles the remote catalog controller; the lower slot toggles the remote main-menu controller. Opening one closes the other. Game controllers still prepend matching official-icon buttons.

`loader.lua` downloads and `loadstring`-compiles `game_catalog.lua` v1, `main_menu.lua` v2, and `player_service.lua` v1. The main context exposes ordered control descriptors, category icon resolution, control services, player snapshots/actions, and stats snapshot subscriptions without exposing `State`, `UI.Controls`, or legacy instances. Player behavior remains in its own module/register frame. Lighting/RGB descriptors are remapped to the new `Lighting` category while stable flags remain unchanged.

Cold-start/MM2 revision: loader concurrently caches catalog, main-menu, player-service, MM2 view, and MM2-service source before consumers compile them. It compiles `mm2_service.lua` in its own frame and exposes only `CreateService` through the MM2 game context. Critical sound templates are preloaded through `ContentProvider`; playback clones loaded templates and skips unavailable sounds. The loader mark and two base rail icons settle to `Ready`/`Failed` before ready-state release. The game context now supplies name/place/banner resolution, service factory, and loader-owned overlay claim callbacks.

Main-menu integration is constructed inside its own immediately invoked function scope. This is a required executor compatibility boundary: the monolithic loader already keeps many top-level locals alive, and declaring the main-menu helper functions in that outer frame exceeded Luau's 200-local-register allocation at `loadMainMenuController`, aborting before any runtime UI could start. The isolated scope preserves the exact service/controller contract while keeping its helper registers out of the loader's outer frame.

Rework target: keep `loader.lua` as a small executor bootstrap. Move feature behavior behind controllers and UI registration behind descriptors while preserving the one-line remote entrypoint.

Critical guarantees: second execution unloads the prior instance; all render-step names and connections are released; altered client state is restored; missing executor APIs degrade explicitly.

Loader runtime reports still represent actual completed or starting construction sections from 6% through 99%, now including remote catalog availability at 98% and remote main-menu availability at 98.5% before executor API cleanup. Each report maps to the existing monotonic 30-step sequence; the explicit 100% call alone releases checkpoint 30.

At checkpoint 30, its 0.14-second fill tween completes before the bar silently collapses into its center over 0.7 seconds; only then does the sole final pop play at speed 0.60 while the upward/growing green `Everything Ready!` switches to Nunito Black (`Heavy`) at 2.10 scale. The completed state holds for 1.8 seconds. Exit behavior is otherwise unchanged.

Runtime validation follows `../EXECUTOR_TESTING.md`. Visual code follows `../THEME_RULES.md`.

## Main UI improvement-pass responsibilities

- Measures boot duration from the first loader statement and exposes the completed value to the Home view before `main_menu.lua` creates its initial page.
- Owns the central `MainIconUrls`/`MainIconAssets` registry and `SetMainIcon` API for player action artwork. The resolver accepts numeric Roblox decal IDs, `rbxassetid://` strings, and HTTPS sources through the existing executor cache.
- Makes every registered toggle bindable through the one existing input router and exposes `GetKeybind`/`BeginKeybind` to the main view. Sliders, dropdown values, and text inputs are not toggle binds.
- Presents ten main categories, with `Waypoints` separate from `Misc`, and adapts waypoint actions as executable descriptors. Saved waypoints are namespaced by experience ID with migration from the old flat array.
- The visible Home unload descriptor is owned by `main_menu.lua`; the legacy Unload descriptor stays registered for compatibility but has `MainHidden = true`.
- Unload disables feature state before destroying views: Aim/ESP, movement/fling/orbit/anti-fling, gravity, camera/freecam, world modifiers, stats, and RGB scopes are turned off, then flat textures, Atmosphere, local transparency, movement, and camera ownership are restored synchronously.
- ESP destruction now destroys only TasuHub-owned instances. It must never iterate arbitrary record values because `WorldCharacter` references a live player Character.
- `NoFog` owns exact Atmosphere snapshots in addition to Lighting fog distances. Flat-texture snapshots use strong ownership until restoration so changed instances cannot disappear from the restore table.
- Godmode and user-adjustable fling-power state are removed. Old config keys are accepted only long enough to clear them during migration.

Executor verification for this pass is pending; compilation alone is not runtime acceptance.

## Persistence and visual-layer refinement

- `ScreenGui.ZIndexBehavior` is `Global`. ESP GUI primitives remain in the 1–4 band, while catalog/main/rail/game windows retain their 2000+ bands, so cheat visuals cannot cover TasuHub windows.
- The selected theme and catalog favorites live in the versioned global preference file `TasuHub/preferences_v1.json`. Loader reads it before visible composition and supplies copied favorite state plus a narrow save callback to the catalog. Theme application saves immediately. Normal config payloads omit the theme, legacy config theme fields are ignored, and Reset to Defaults preserves the preferred theme.
- Orbit player/mode descriptor host frames are explicitly assigned to `Misc/Orbit` before cloning, preventing the adapter from dropping their dropdowns as anonymous `Frame/Frame` controls.
- Freecam look uses the captured Roblox sensitivity with coefficient `0.009`.
- ESP box ownership uses body-only proxies with one AlwaysOnTop `BoxHandleAdornment` fill and twelve AlwaysOnTop 3D edges. `SelectionBox` and screen-GUI rectangle boxes are removed; projected bounds remain solely for the attached health bar.
