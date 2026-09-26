# System memory: script loading and catalog

Keep the user flow: built-in entries, saved entries, URL/source execution, edit/delete, banner lookup, and capability feedback.

Rework requirements: separate catalog data from its view; validate HTTPS URLs and source presence; return structured compile/runtime errors; version remote modules; prevent duplicate execution; preserve text/icon fallback when images fail.

The system consumes shared theme components and never constructs a private catalog palette or modal.

The upper post-loader corner button, using Roblox decal `137753054375497`, now opens the first reworked catalog view. It no longer invokes unload. The view is delivered by contract-version-1 `game_catalog.lua`, downloaded from the `codex/ui-rework` raw GitHub branch and compiled with executor `loadstring`; there is no embedded UI fallback. Loader-owned services remain responsible for validated execution and cover resolution, while the remote module owns only catalog composition, filtering, immutable display status, and open/close state.

`executeCatalogEntry` now returns structured `{Ok, Message}` results, validates an entry, enforces the MM2 place constraint, requires HTTPS when source is absent, reports download/compile/runtime errors, and locks a stable entry identity after successful execution so it cannot be started twice within the same TasuHub lifetime. Failed download/compile/runtime attempts release the lock for correction/retry. The dormant legacy catalog wrapper consumes the same result only for compatibility; the new module writes results into its opaque footer rather than invoking the hidden legacy toast.

The remote module ignores every entry-provided `Status` and `Features` field. It freezes its private built-in metadata, assigns the remote default `Supported` to other real catalog entries, and exports no mutation path. Five preview entries exist only to exercise the finished grid with real-game covers; they are explicitly marked non-executable and surface a red reason toast rather than reaching `executeCatalogEntry`. Cards with `Un-Supported` status are also non-executable in the view. This is runtime contract integrity, not encryption against an executor owner.

Automatic cover lookup follows `PlaceId → UniverseId → official 768×432 game thumbnail → TasuHub/Catalog/Banners/<PlaceId>.png → executor custom asset`. Failure retains the fixed cover fallback. The catalog grid supports three cards per row and vertical scrolling; the current executable built-in data contains MM2, saved entries continue to flow from `State.Catalog`, and preview cards never enter saved state.

Executor checks: verify the remote module request and version contract; open/close from every dock edge; drag from header/footer; search by name/status/place ID/feature; resolve all visible covers; confirm preview activation never reaches the execution service; load the built-in MM2 entry in and outside its game; load a saved source entry; exercise duplicate activation, a bad URL, compile/runtime errors, cover failure, module failure, feedback colors/shake/toast, and unload during every transition.
