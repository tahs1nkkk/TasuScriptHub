# Script memory: game_catalog.lua

Role: versioned remote UI module for the reworked game/script catalog.

The module returns a frozen contract-version-1 table with one `Create(context)` factory. It is fetched from the `codex/ui-rework` raw GitHub branch and compiled only through executor `loadstring`; it is never adapted for Roblox Studio and has no embedded fallback inside `loader.lua`.

The factory receives `InterfaceRoot`, the shared `Base`/`Layer`/`Signal` colors, shared Nunito/BuilderSans fonts, all catalog/control motion tokens, the central animation/audio/lifecycle functions, live anchor/viewport providers, a copied catalog-entry provider, and loader-owned execution/cover services. It constructs one hidden `GameCatalogRoot` and returns a frozen controller exposing only `Open`, `Close`, `Toggle`, `IsOpen`, and `Destroy`. It contains no private palette, font, or duration registry.

Revision-1 composition: responsive maximum 1000×680 popup; opaque 70 px header and 46 px footer; 80%-transparent middle body; centered `Oyun Kataloğu` title; right search and close controls; left-expanding local search input; vertically scrolling three-column grid; fixed 252 px cards with 142 px automatic Roblox cover, cover-width divider, official status, name, and run hint; footer result/count text.

The official status map is private and frozen. MM2 is `Stable`; entries without a remote built-in mapping receive remote default `Supported`; entry-provided `Status` fields are discarded. No setter or status table is returned. `Un-Supported` cards do not call the execution service.

Open/close uses a revision-guarded pull transition. It samples the upper corner button's current center when opening and samples it again at the final close leg, so redocking while open changes the return target. A dedicated opaque transition fill owns both shell-size phases; the actual header/body/footer content crossfades only at full size and fades away before contraction, preventing visible grid reflow while preserving the body's true 0.80 transparency. Search and cover continuations verify ownership/destroyed state.

Executor acceptance: verify remote fetch/compile/version, one-controller ownership, all four dock anchor paths, interruption/re-entry during open and close, current-position close targeting, exact opaque/80%-transparent regions, responsive three-column scrolling, search open/filter/close, cover success/fallback, immutable displayed status despite an entry `Status` field, structured execution messages, MM2 place rejection, duplicate run rejection, and complete unload cleanup.
