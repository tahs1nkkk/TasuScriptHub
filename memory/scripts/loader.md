# Script memory: loader.lua

Role: canonical executor entrypoint and current monolithic TasuHub runtime.

Current responsibilities include defaults/state, capability detection, lifecycle tracking, legacy UI, search, players, catalog, configs, Aim, Visuals, Movement, World, Misc, statistics, and unload.

Implemented rework step: the old card/radial loader was replaced with the approved translucent dark loader. `loader.lua` now owns reusable 392 px icon registry entry `TasuHub`, backed solely by a runtime thumbnail-download/custom-asset pipeline for multicolor Roblox decal `138667112902223` with no fallback geometry. The asset is a hard pre-entry dependency with a 20-attempt/0.5-second retry policy and invisible failure cleanup. On success the loader uses the stronger 0.58 → 1.16 icon arrival, a 1.5× faster fixed-anchor breathing/rock ambient loop, tracked background blur, a constant-speed upward 60×22 halftone loop starting at 44% viewport height, remembered dot baselines with zero-opacity wrap endpoints, a shadow-free composition, semantic loader tokens, a white track with gray 30-checkpoint fill and white percentage text, live runtime-bound Turkish status text, pitch-rising checkpoint audio, and the whole-background downward/fade exit.

Current presentation state: `UI.LegacyUIEnabled` is permanently false during the rebuild. The legacy top bar, content window, search, preview, stats, toast, modal entrypoints, and unload screen cannot become visible. Feature engines, state, flags, lifecycle, and executor APIs remain loaded. After the loader is destroyed, the new `InterfaceRoot` reveals two identical 70 px base buttons in a four-edge dock plus its silent visibility bar. The upper slot toggles the remote catalog controller; the lower slot toggles the remote main-menu controller. Opening one closes the other. Game controllers still prepend matching official-icon buttons.

`loader.lua` downloads and `loadstring`-compiles both `game_catalog.lua` and `main_menu.lua`, validates contract version 1, and passes only shared services plus narrow callbacks. The main context exposes copied stable control descriptors and `Get`/`Set`/`Activate`/options/visibility services; the module never receives `State`, `UI.Controls`, or legacy instances. Added shared tokens cover the 230→72 px sidebar, 46 px category rows, 18 px content padding, 12 px section gap, 0.38-second sidebar motion, and 0.24/0.34 page transitions while reusing catalog window/header/search geometry. Existing catalog/game-controller responsibilities remain unchanged.

Rework target: keep `loader.lua` as a small executor bootstrap. Move feature behavior behind controllers and UI registration behind descriptors while preserving the one-line remote entrypoint.

Critical guarantees: second execution unloads the prior instance; all render-step names and connections are released; altered client state is restored; missing executor APIs degrade explicitly.

Loader runtime reports still represent actual completed or starting construction sections from 6% through 99%, now including remote catalog availability at 98% and remote main-menu availability at 98.5% before executor API cleanup. Each report maps to the existing monotonic 30-step sequence; the explicit 100% call alone releases checkpoint 30.

At checkpoint 30, its 0.14-second fill tween completes before the bar silently collapses into its center over 0.7 seconds; only then does the sole final pop play at speed 0.60 while the upward/growing green `Herşey Hazır!` switches to Nunito Black (`Heavy`) at 2.10 scale. The completed state holds for 1.8 seconds. The soft UI whoosh begins simultaneously with exit motion at volume 0.09, stretches to three seconds at `2/3` speed, and uses 1.5 octave pitch compensation. Entry is 0.5 seconds; the whole-background exit is exactly three times faster than its preceding 1.7-second profile (`1.7/3`, approximately 0.567 seconds), linearly fades the root `CanvasGroup`, removes the size-34 tracked blur, and disconnects the ambient dot/icon animation after fully leaving.

Runtime validation follows `../EXECUTOR_TESTING.md`. Visual code follows `../THEME_RULES.md`.
