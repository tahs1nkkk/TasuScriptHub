# System memory: legacy UI retirement

Status: no legacy presentation is allowed to appear after the loader.

`UI.LegacyUIEnabled` is fixed to `false` during the rebuild. Every legacy visual root is also parented below `LegacyUIRoot`, whose `Visible` property remains false. Automatic top-bar reveal, content-window opening, global search, stats panel, visual preview, toast notifications, old unload screen, and exported `Open`/`Toggle`/`ShowCategory` paths are disabled or redirected to non-visual results.

The legacy builders remain dormant temporarily because current `UI.Flags` setters and some feature registration paths still reference their controller objects. This is not permission to reuse or restyle them. Each builder is physically removed when its state/controller contract has a replacement.

Feature engines remain active: state, `SetFlag`/`GetFlag`, Aim, Visuals, Movement, World, MM2 catalog loading, lifecycle, config functions, and unload cleanup are preserved.

Executor acceptance: after loader fade, confirm that no old top bar, card, window, search, modal, toast, stats panel, preview, or unload artwork appears. Exercise programmatic `Open`, `Toggle`, and `ShowCategory` and confirm they do not reveal legacy UI. Then enable representative feature flags programmatically and confirm feature overlays/engines still operate.
