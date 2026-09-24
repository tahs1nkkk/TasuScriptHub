# Script memory: loader.lua

Role: canonical executor entrypoint and current monolithic TasuHub runtime.

Current responsibilities include defaults/state, capability detection, lifecycle tracking, legacy UI, search, players, catalog, configs, Aim, Visuals, Movement, World, Misc, statistics, and unload.

Implemented rework step: the old card/radial loader was replaced with the approved translucent dark loader. `loader.lua` now owns the reusable vector icon registry entry `TasuHub`, tracked background blur, dense lower-60% responsive dot grid, one black right/down soft-shadow copy per loader element, semantic loader tokens, a white track with black horizontal progress fill, clipped negative percentage text, live Turkish status text, Roblox-linked audio cues, and the whole-background downward exit.

Current presentation state: `UI.LegacyUIEnabled` is permanently false during the rebuild. The legacy top bar, content window, search, preview, stats, toast, modal entrypoints, and unload screen cannot become visible. Feature engines, state, flags, lifecycle, and executor APIs remain loaded.

Rework target: keep `loader.lua` as a small executor bootstrap. Move feature behavior behind controllers and UI registration behind descriptors while preserving the one-line remote entrypoint.

Critical guarantees: second execution unloads the prior instance; all render-step names and connections are released; altered client state is restored; missing executor APIs degrade explicitly.

Loader runtime checkpoints currently report 6%, 22%, 44%, 70%, 90%, and 100%. These are construction milestones, not network-byte measurements.

At the 100% checkpoint, the final 1.4 second fill tween completes, the bar collapses into its center over 0.7 seconds, and the status shifts upward, grows, and displays green `Herşey Hazır!`. The completed state holds for 2.5 seconds. Entry is 0.5 seconds; the whole-background exit is 2 seconds and removes the size-34 tracked blur as it leaves.

Runtime validation follows `../EXECUTOR_TESTING.md`. Visual code follows `../THEME_RULES.md`.
