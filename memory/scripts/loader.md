# Script memory: loader.lua

Role: canonical executor entrypoint and current monolithic TasuHub runtime.

Current responsibilities include defaults/state, capability detection, lifecycle tracking, hidden compatibility UI, descriptors, catalog/configs, feature engines, statistics sampling, remote module composition, and unload.

Implemented rework step: the old card/radial loader was replaced with the approved translucent dark loader. `loader.lua` owns the 392 px TasuHub asset pipeline, staged entry, ambient icon/grid motion, 30 runtime-bound checkpoints, English status text, tracked blur, and whole-background downward/fade exit.

Current presentation state: `UI.LegacyUIEnabled` is permanently false during the rebuild. The legacy top bar, content window, search, preview, stats, toast, modal entrypoints, and unload screen cannot become visible. Feature engines, state, flags, lifecycle, and executor APIs remain loaded. After the loader is destroyed, the new `InterfaceRoot` reveals two identical 70 px base buttons in a four-edge dock plus its silent visibility bar. The upper slot toggles the remote catalog controller; the lower slot toggles the remote main-menu controller. Opening one closes the other. Game controllers still prepend matching official-icon buttons.

`loader.lua` downloads and `loadstring`-compiles `game_catalog.lua` v1, `main_menu.lua` v2, and `player_service.lua` v1. The main context exposes ordered control descriptors, category icon resolution, control services, player snapshots/actions, and stats snapshot subscriptions without exposing `State`, `UI.Controls`, or legacy instances. Player behavior remains in its own module/register frame. Lighting/RGB descriptors are remapped to the new `Lighting` category while stable flags remain unchanged.

Main-menu integration is constructed inside its own immediately invoked function scope. This is a required executor compatibility boundary: the monolithic loader already keeps many top-level locals alive, and declaring the main-menu helper functions in that outer frame exceeded Luau's 200-local-register allocation at `loadMainMenuController`, aborting before any runtime UI could start. The isolated scope preserves the exact service/controller contract while keeping its helper registers out of the loader's outer frame.

Rework target: keep `loader.lua` as a small executor bootstrap. Move feature behavior behind controllers and UI registration behind descriptors while preserving the one-line remote entrypoint.

Critical guarantees: second execution unloads the prior instance; all render-step names and connections are released; altered client state is restored; missing executor APIs degrade explicitly.

Loader runtime reports still represent actual completed or starting construction sections from 6% through 99%, now including remote catalog availability at 98% and remote main-menu availability at 98.5% before executor API cleanup. Each report maps to the existing monotonic 30-step sequence; the explicit 100% call alone releases checkpoint 30.

At checkpoint 30, its 0.14-second fill tween completes before the bar silently collapses into its center over 0.7 seconds; only then does the sole final pop play at speed 0.60 while the upward/growing green `Everything Ready!` switches to Nunito Black (`Heavy`) at 2.10 scale. The completed state holds for 1.8 seconds. Exit behavior is otherwise unchanged.

Runtime validation follows `../EXECUTOR_TESTING.md`. Visual code follows `../THEME_RULES.md`.
