# System memory: executor capability detection

Capabilities include HTTP request paths, `loadstring`, file/folder APIs, custom asset loading, hidden UI parenting, input movement, touch/proximity helpers, and any executor-specific global used by a feature.

Resolve globals once through a normalized capability service. Feature code requests a capability and supplies a safe fallback or an explicit unsupported result.

The TasuHub decal loader requires HTTP, file/folder, and custom-asset capabilities. It resolves the current Roblox thumbnail URL at runtime and writes the PNG into `TasuHub/Icons`. There is no fallback and the asset is now a hard pre-UI gate: the loader stays completely invisible and silent while resolution retries up to 20 times at 0.5-second intervals. Missing required capabilities or exhausted retries mark the icon failed, clean the still-hidden loader state, and raise an explicit error before feature construction begins. It never substitutes a Studio-only path.

Corner-action icons first receive their executor-safe `rbxassetid://` Roblox source, then reuse the thumbnail → PNG file → executor custom-asset path as the preferred resolved source. Slot 1 resolves catalog decal `137753054375497`; slot 2 resolves general-menu decal `83533116222028`. Their cache names are stable per slot (`CornerButton1.png` and `CornerButton2.png`), and revision guards prevent an older request from overwriting a newer asset choice. `ensureFolder` rechecks folder existence after a failed creation call so simultaneous icon workers cannot fail merely because another worker won the same creation race. No Studio asset-loading substitute is permitted.

The game-catalog UI requires executor HTTP and `loadstring` to download and compile contract-version-1 `game_catalog.lua`. A request, compile, runtime, or contract mismatch records `UI.GameCatalogError`; the upper button warns and performs no fallback UI construction. Cover resolution additionally requires HTTP, file/folder, and custom-asset capabilities and fails per card into its fixed fallback without blocking the menu.

Never add Studio substitutes. Capability results are included in diagnostics but must not expose sensitive executor data.

Executor checks: full-capability executor, missing file APIs, missing custom assets, missing request API with `game:HttpGet` fallback, and missing feature-specific helpers.
