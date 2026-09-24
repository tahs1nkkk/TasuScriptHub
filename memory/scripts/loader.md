# Script memory: loader.lua

Role: canonical executor entrypoint and current monolithic TasuHub runtime.

Current responsibilities include defaults/state, capability detection, lifecycle tracking, legacy UI, search, players, catalog, configs, Aim, Visuals, Movement, World, Misc, statistics, and unload.

Implemented rework step: the old card/radial loader was replaced with the approved translucent dark loader. `loader.lua` now owns reusable 280 px icon registry entry `TasuHub`, backed solely by a runtime thumbnail-download/custom-asset pipeline for multicolor Roblox decal `138667112902223` with no fallback geometry, plus its fixed-anchor breathing/rock ambient loop, tracked background blur, a constant-speed upward 60×22 halftone loop driven through 22 optimized row groups, remembered dot baselines with zero-opacity wrap endpoints, a shadow-free loader composition, semantic loader tokens, a white track with gray horizontal progress fill and white percentage text, live runtime-bound Turkish status text, Roblox-linked audio cues, and the whole-background downward/fade exit.

Current presentation state: `UI.LegacyUIEnabled` is permanently false during the rebuild. The legacy top bar, content window, search, preview, stats, toast, modal entrypoints, and unload screen cannot become visible. Feature engines, state, flags, lifecycle, and executor APIs remain loaded. After the loader is destroyed, the new `InterfaceRoot` reveals two identical 70 px buttons in a right-edge dock plus a silent flush visibility line. The dock can be dragged only among the four viewport edges, preserves its along-edge ratio, and hides the stack through the active edge. Hover/press feedback directly animates clipping-safe button and icon sizes together; hover uses a dedicated tick while activation uses the former hover click. The upper catalog slot uses decal `137753054375497` and temporarily executes canonical unload; the lower general-menu slot uses decal `83533116222028` and remains inert until the next design step. The exported icon/action/visibility/dock setters and semantic definitions are the only configuration path.

Rework target: keep `loader.lua` as a small executor bootstrap. Move feature behavior behind controllers and UI registration behind descriptors while preserving the one-line remote entrypoint.

Critical guarantees: second execution unloads the prior instance; all render-step names and connections are released; altered client state is restored; missing executor APIs degrade explicitly.

Loader runtime checkpoints now report actual completed or starting construction sections from 6% through 99%: Core, UI, Categories, Search, Aim, Visuals, Runtime engines, Movement, World, Players, Catalog, Configs, and executor API cleanup. `UI.ReportLoading` yields one scheduler frame after each boundary so short-lived headings are visible; these are construction milestones, not network-byte measurements or a simulated timer.

At the 100% checkpoint, the final 1.4 second fill tween completes, the bar silently collapses into its center over 0.7 seconds, and only then does the final pop accompany the upward/growing green `Herşey Hazır!` at 1.40 scale. The completed state holds for 1.8 seconds. The soft UI whoosh begins simultaneously with exit motion at volume 0.09, stretches to three seconds at `2/3` speed, and uses 1.5 octave pitch compensation. Entry is 0.5 seconds; the whole-background exit is exactly three times faster than its preceding 1.7-second profile (`1.7/3`, approximately 0.567 seconds), linearly fades the root `CanvasGroup`, removes the size-34 tracked blur, and disconnects the ambient dot/icon animation after fully leaving.

Runtime validation follows `../EXECUTOR_TESTING.md`. Visual code follows `../THEME_RULES.md`.
