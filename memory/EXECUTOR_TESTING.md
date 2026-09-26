# Executor-only validation

Roblox Studio is not a supported target. No test, compatibility shim, LocalScript wrapper, plugin workflow, Command Bar workflow, `TestService` harness, or Studio-only service substitution may be added.

## Canonical entrypoint

```lua
assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/tahs1nkkk/TasuScriptHub/refs/heads/main/loader.lua")))()
```

The entrypoint must remain a single-file bootstrap. If the project becomes modular, `loader.lua` owns remote module acquisition, error reporting, version agreement, and cleanup.

## Meaning of a pass

- Luau compilation is only a preflight check; it is never proof of runtime correctness.
- A runtime pass must occur in the intended executor and Roblox client.
- Record executor name/version, game/place, client state, error text and line, and whether this was first load, reload, respawn, or teleport.
- Unsupported executor capabilities must degrade through explicit capability checks and user-facing status, not silent failure.

## Required smoke sequence

1. Execute the canonical entrypoint on a fresh client.
2. Confirm the loader stays completely invisible and silent until its required TasuHub icon resolves, then completes normally with main shell visibility, input, drag, and category navigation. Also verify explicit cleanup/abort when the required icon capability path is unavailable; no fallback is permitted.
3. Execute the entrypoint again and confirm the previous instance unloads without duplicate connections or render-step bindings.
4. Toggle every feature on and off once; restore altered character, camera, lighting, collision, and gravity state.
5. Respawn and repeat features that bind to character parts or humanoids.
6. Exercise player join/leave, player selection, search indexing, remote catalog module load, and the catalog revision-6 paths: immediate open/close from every dock edge with no callback/frame delay; smooth overlay reveal without a nested-body `CanvasGroup`; exactly one initial virtual-page build; zero cards and an empty hidden canvas after close completes; cleared session cover cache and fresh card/cover reload on the next open; rejection of late covers from an earlier generation; interruption; exact whole-window zero-scale return; drag from every non-interactive header/footer region while switch/search/close retain input; hover/pinned/cleared search with its protected internal count; default hidden unsupported entries and `Tümü` reveal; `Stable → Supported → Un-Supported` plus alphabetic order; equal three-column widths/strokes and 20 px inset; status strips with square top corners and image-matched lower corners; no more than nine live cards/cover requests; rolling 3×3 window swaps; compact status feedback; cover fallback; and unload during each asynchronous state. Launch MM2 in its supported place and confirm the catalog closes, exactly one official square-icon game button is prepended, and the 620×420 shared-theme game window opens automatically from that button. Toggle the MM2 window, drag it from non-control header/footer areas, verify all five state controls plus both manual actions, preserve feature state across view close/reopen, and unload during its open/close motion and icon resolution. Then exercise config save/load and final unload.
7. Review executor console for uncaught errors and repeated warnings.

## Feature acceptance

Each feature memory file contains focused checks. A feature is not migrated merely because its control appears; enable, update, disable, respawn, reload, and unload paths must all be verified when relevant.
