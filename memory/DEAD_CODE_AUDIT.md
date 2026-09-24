# Dead-code audit

Audit baseline: executor-verified remote content `c23ef7c`; local rework source matches it.

## Confirmed dead state

- `Defaults.Aim.AliveCheck` is declared but never read or written by runtime or UI code. Remove it when the Aim controller is migrated, or deliberately implement the behavior and update `features/aim-targeting.md`.

## Compatibility-only state

- `State.Aim.HoldRightMouse` exists only as a compatibility bridge for `Activation`; do not expose it in the new UI. Migrate old configs, then serialize only `Activation`.
- `State.Interface.RGBEnabled`, `RGBSpeed`, `RGBSaturation`, and `RGBBrightness` are legacy config keys cleared during load. Keep only in a named migration step until the supported config version no longer needs them.

## Live but scheduled for removal with legacy UI

- `getBoundingScreenBox` is currently used by the visual preview. It becomes removable if the old preview implementation is discarded.
- Legacy theme binding, shadow construction, vector icon drawing, card builders, dropdown implementations, global-search view, player-row view, catalog editor view, and config modal remain live today but are not reusable in the new UI.
- Legacy builders still initialize temporarily for compatibility with existing state/flag setters, but every legacy presentation entrypoint is gated by `UI.LegacyUIEnabled = false` and every legacy visual root is isolated below the permanently hidden `LegacyUIRoot`. They are dormant code scheduled for physical removal as replacement controllers land.
- The old loader card, radial `LoaderSegments`, loader title, gradient, and slide-in/slide-out path were removed during the first rework step. No references remain.
- Placeholder methods in the initial `UI` table are intentional forward references, not dead functions.
- `_` locals reported by AST reference counting are intentional ignored return values.

## Script results

- `loader.lua`: no unreferenced named local functions or service bindings were found by AST reference counting. Luau compilation succeeds.
- `mm2.lua`: no unreferenced named local functions or service bindings were found by AST reference counting. Luau compilation succeeds.
- `mm2.lua` owns a second independent UI. Its feature logic is live, but that visual shell must be removed when MM2 becomes a registered feature provider.
- Corner-action audit: `CornerActionRail`, both `CornerButtons` records, all five interaction connections per button, `SetCornerButtonIcon`, `SetCornerButtonAction`, and `ShowCornerButtons` are live through construction, exported configuration, or the post-loader reveal. The two icon definitions and slot 1 action are live; slot 2's absent callback is the explicit next-step boundary rather than an abandoned legacy path. No legacy builder or legacy visibility flag is reused.
- Corner-action assignment audit: both semantic definitions and asset IDs are consumed during construction; slot 1's callback reaches the canonical `unload` function, while slot 2's nil action is an intentional next-step boundary. No duplicate catalog/general-menu launcher or unload implementation was introduced.
- Superseded corner-action revision: `UIListLayout`, per-button `UIScale`, asymmetric upper style, and 60 px geometry were removed in the prior pass. Its temporary 78/84/74 geometry and right-side arrow controller are themselves removed by the dock revision below. The direct Roblox icon source and concurrent-folder recheck remain live.
- Corner dock revision: the obsolete 78/84/74 geometry, 38 px static icon, 3 px stroke, fixed bottom-right anchor, 30×44 arrow/glyph/rotation, arrow sound path, and one-direction hide offsets are removed. Live replacements are 70/76/67 button sizes, synchronized 48/52/46 icon sizes, 6 px stroke, padded clipping-safe stack bounds, a silent adaptive 6×64 edge line, four directional hide paths, nearest-edge drag state, resize re-docking, and click suppression. Both audio presets are live: `ButtonHover` only on entry and `ButtonClick` only on valid activation.

## Confirmed removals

- Loader rework: removed the radial segment spinner and legacy loader card implementation; replaced by the shared vector icon and horizontal progress system.
- Loader exit revision: removed the independent icon/bar/status exit tweens, their stagger/delay tokens, and the unused per-item pop-out audio entry. Exit now has one whole-loader motion path.
- Loader background revision: removed `LoaderTopFade`, its 1000 px exit offset, and all gradient keypoints. Background depth now comes from tracked blur and a lower viewport vector dot grid.
- Loader shadow revision: removed every loader-specific icon, bar, and status shadow instance, scale, reveal path, completion tween, and the temporary black `Shadow` palette token. No loader shadow references remain.
- Loader ambient-motion revision: removed the unused bar-collapse `PopOut` sound call and preset. Dot motion updates only 22 row groups per frame; the 1320 retained dot records exist intentionally as the exact static baseline memory requested for future tuning.
- Loader endpoint/rock revision: removed the obsolete `LoaderIconTravel` translation token and same-position reassignment path. The replacement `LoaderIconRockAngle`, dot endpoint-opacity envelope, white percentage path, larger ready scale, and three-second reverse exit cue are all live; no superseded loader motion or audio branch remains.
- Loader exit-audio timing revision: removed the direct `FadeOut` call from exit-motion start. The sole remaining reverse-cue path is ownership-guarded and scheduled from bar collapse; no duplicate exit sound trigger remains.
- Loader branded-asset/audio revision: `TasuHub` resolves decal `138667112902223` through the one-shot thumbnail-API/download/custom-asset pipeline; the complete frame-built fallback (`VectorFallback`, four icon parts, color handling, and load swap) is removed. Exit-audio delay remains zero, while the horror-like reverse asset `9120699503`, `7/3` speed profile, and three-second target are replaced by soft two-second UI asset `90657541635248` at volume 0.08. No superseded fallback or exit-sound path remains.
- Loader duration revision: confirmed `UI.IconLibrary.TasuHub` still constructs only its asset `ImageLabel` and no fallback. The soft UI sound remains asset `90657541635248`, now stretched to three seconds with pitch compensation; the obsolete speed-1/volume-0.08/two-second profile and 2-second exit token are removed in favor of volume 0.07, `2/3` speed, 1.5 octave compensation, and a 1.7-second exit.
- Loader fast-exit revision: the 1.7-second exit constant and volume-0.07 sound profile are superseded. The live exit token is the exact `1.7/3` expression and the same three-second pitch-compensated soft cue now uses volume 0.09; no parallel closing tween or duplicate audio preset was introduced.
- Legacy visibility pass: removed the old unload animation and disabled automatic top-bar reveal, window/search opening, stats, preview, visual notifications, and exported legacy open/toggle/category methods.
- Theme retirement: removed the `Tasu Light`, `Midnight`, and `Amethyst` preset definitions. Legacy config names now resolve to the sole `Rework Dark` three-color theme.

## Re-run rules

After each migration, check Luau compilation, named local references, state-key reads/writes, service usage, render-step bindings, connections, exported API members, and executor unload behavior. Record confirmed removals with commit IDs.
