# System memory: legacy UI retirement

Status: no legacy presentation is allowed to appear after the loader.

`UI.LegacyUIEnabled` is fixed to `false` during the rebuild. Every legacy visual root is also parented below `LegacyUIRoot`, whose `Visible` property remains false. Automatic top-bar reveal, content-window opening, legacy global search, stats panel, visual preview, toast notifications, and old unload screen stay disabled. Exported `Open`/`Close`/`Toggle`/`ShowCategory` now route only to the remote main-menu controller and can never reveal legacy instances.

The legacy builders remain dormant temporarily because current `UI.Flags` setters and some feature registration paths still reference their controller objects. This is not permission to reuse or restyle them. Each builder is physically removed when its state/controller contract has a replacement.

Feature engines remain active: state, `SetFlag`/`GetFlag`, Aim, Visuals, Movement, World, catalog loading, lifecycle, config functions, and unload cleanup are preserved. MM2 is the first game module whose old private blue 390×250 `ScreenGui` has been physically removed. Its feature engine now feeds a shared-theme controller window below `InterfaceRoot`; no old MM2 visual may be restored as a fallback.

Executor acceptance: after loader fade, confirm that no old top bar, card, window, search, modal, toast, stats panel, preview, MM2 blue shell, or unload artwork appears. Exercise programmatic `Open`, `Toggle`, and `ShowCategory`; only `MainMenuRoot` may appear. Launch MM2 through the catalog and confirm only the new smaller shared-theme game window appears while its engines still operate.
