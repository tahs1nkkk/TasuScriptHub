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
6. Exercise player join/leave, player selection, search indexing, remote catalog module load, and the catalog revision-7 paths: retain revision-6 immediate open/close, single initial virtual page, zero closed cards, fresh cover reload, late-cover rejection, interruption, exact origin transition, drag surfaces, protected search count, deterministic status/alphabetic order, equal cards/status corners, maximum nine live cards, compact feedback, and cover fallback. Confirm the former header switch is gone; open the three-line drawer; verify it and its launcher slide entirely inside the clipped catalog; click outside to dismiss without activating the covered control; close the catalog with the drawer open; exercise show-all and favorites switches; select/deselect every square feature checkbox; combine multiple features with AND behavior and search; verify empty results; and verify default/hover/selected/removal-hover PNG star states. Favorites must survive rolling-page destruction and catalog close/reopen, but clear after hub unload/re-execution. Unload during drawer/card animations and confirm no stale completion or connection survives. Launch MM2 in its supported place and confirm the catalog closes, exactly one official square-icon game button is prepended, and the 620×420 shared-theme game window opens automatically from that button. Toggle the MM2 window, drag it from non-control header/footer areas, verify all five state controls plus both manual actions, preserve feature state across view close/reopen, and unload during its open/close motion and icon resolution. Then exercise config save/load and final unload.
7. Review executor console for uncaught errors and repeated warnings.

## Feature acceptance

Each feature memory file contains focused checks. A feature is not migrated merely because its control appears; enable, update, disable, respawn, reload, and unload paths must all be verified when relevant.
