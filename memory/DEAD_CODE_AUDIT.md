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
- Placeholder methods in the initial `UI` table are intentional forward references, not dead functions.
- `_` locals reported by AST reference counting are intentional ignored return values.

## Script results

- `loader.lua`: no unreferenced named local functions or service bindings were found by AST reference counting. Luau compilation succeeds.
- `mm2.lua`: no unreferenced named local functions or service bindings were found by AST reference counting. Luau compilation succeeds.
- `mm2.lua` owns a second independent UI. Its feature logic is live, but that visual shell must be removed when MM2 becomes a registered feature provider.

## Re-run rules

After each migration, check Luau compilation, named local references, state-key reads/writes, service usage, render-step bindings, connections, exported API members, and executor unload behavior. Record confirmed removals with commit IDs.

