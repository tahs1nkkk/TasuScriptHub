# System memory: script loading and catalog

Keep the user flow: built-in entries, saved entries, URL/source execution, edit/delete, banner lookup, and capability feedback.

Rework requirements: separate catalog data from its view; validate HTTPS URLs and source presence; return structured compile/runtime errors; version remote modules; prevent duplicate execution; preserve text/icon fallback when images fail.

The system consumes shared theme components and never constructs a private catalog palette or modal.

The upper post-loader corner button, using Roblox decal `137753054375497`, now opens the first reworked catalog view. It no longer invokes unload. The view is delivered by contract-version-1 `game_catalog.lua`, downloaded from the `codex/ui-rework` raw GitHub branch and compiled with executor `loadstring`; there is no embedded UI fallback. Loader-owned services remain responsible for validated execution and cover resolution, while the remote module owns only catalog composition, filtering, immutable display status, and open/close state.

`executeCatalogEntry` now returns structured `{Ok, Message}` results, validates an entry, enforces the MM2 place constraint, requires HTTPS when source is absent, reports download/compile/runtime errors, and locks a stable entry identity after successful execution so it cannot be started twice within the same TasuHub lifetime. Failed download/compile/runtime attempts release the lock for correction/retry. The dormant legacy catalog wrapper consumes the same result only for compatibility; the new module writes results into its opaque footer rather than invoking the hidden legacy toast.

The remote module ignores every entry-provided `Status` field. It freezes its private built-in status map (`mm2 = Stable`), assigns the remote default `Supported` to other catalog entries, and exports no mutation path. Cards with `Un-Supported` status are non-executable in the view. This is runtime contract integrity, not encryption against an executor owner.

Automatic cover lookup follows `PlaceId → UniverseId → official 768×432 game thumbnail → TasuHub/Catalog/Banners/<PlaceId>.png → executor custom asset`. Failure retains the fixed cover fallback. The catalog grid supports three cards per row and vertical scrolling; the current built-in data contains MM2, while saved entries continue to flow from `State.Catalog`.

Executor checks: verify the remote module request and version contract; open/close from every dock edge; search by name/status/place ID; resolve an MM2 cover; load the built-in MM2 entry in and outside its game; load a saved source entry; exercise duplicate activation, a bad URL, compile/runtime errors, cover failure, module failure, and unload during every transition.
