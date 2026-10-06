# Executor-only validation

Roblox Studio is not a supported target. No test, compatibility shim, LocalScript wrapper, plugin workflow, Command Bar workflow, `TestService` harness, or Studio-only service substitution may be added.

## Canonical entrypoint

```lua
assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/tahs1nkkk/TasuScriptHub/refs/heads/main/loader.lua")))()
```

The entrypoint must remain a single-file bootstrap. If the project becomes modular, `loader.lua` owns remote module acquisition, error reporting, version agreement, and cleanup.

## Meaning of a pass

- Luau compilation is only a preflight check; it is never proof of runtime correctness. The preflight must generate bytecode (for example compiler `--null` mode), not stop after parsing, so local-register allocation failures are detected.
- A runtime pass must occur in the intended executor and Roblox client.
- Record executor name/version, game/place, client state, error text and line, and whether this was first load, reload, respawn, or teleport.
- Unsupported executor capabilities must degrade through explicit capability checks and user-facing status, not silent failure.

## Required smoke sequence

1. Execute the canonical entrypoint on a fresh client. Treat any `Out of local registers` error as a bootstrap failure; no loader or UI behavior can be considered tested after it.
2. Confirm the loader stays completely invisible and silent until its required TasuHub icon resolves, then completes normally with main shell visibility, input, drag, and category navigation. Also verify explicit cleanup/abort when the required icon capability path is unavailable; no fallback is permitted.
3. Execute the entrypoint again and confirm the previous instance unloads without duplicate connections or render-step bindings.
4. Toggle every feature on and off once; restore altered character, camera, lighting, collision, and gravity state.
5. Respawn and repeat features that bind to character parts or humanoids.
6. Exercise player join/leave, player selection, search indexing, remote catalog module load, and the catalog revision-10 paths: retain revision-9 rounded cover/status behavior, revision-8 filtering/favorites/error feedback, revision-6 motion/virtualization/cleanup, and the maximum-nine-card limit. While a card is hovered, open the filter drawer and confirm its warning outline, scale, surface emphasis, and favorite control immediately return to rest. Move over the entire drawer and confirm no underlying card hover sound, presentation, or activation occurs; close it and confirm normal hover resumes on the next pointer entry. Confirm the filter drawer itself remains visually unchanged. Retest close/reopen, rolling-page replacement, late cover rejection, unload during animations/audio, MM2 launch/window controls, config save/load, and final unload.
7. Exercise main-menu revision 1 through corner slot 2. Confirm it matches the catalog's outer size/radius/header/search geometry but has no footer; slot 1 and slot 2 close one another. Verify the 230 px category rail is expanded by default, every horizontal category button changes page, and collapsing leaves usable 48×46 icon controls while the page host smoothly expands from the right and recenters. On every category change, confirm the old page moves/fades upward and the new page enters from above without overlapping stale inputs. Test toggle, slider, dropdown/player selector, input, and action views against their preserved engines; verify conditional visibility and external/hotkey refresh. Test empty/non-empty/cleared search, result counts, category/control navigation, target scroll/highlight, header dragging, close/reopen, rapid category/sidebar/search/open-close reversal, double execution, and unload mid-animation. At no point may a legacy top bar, window, search, preview, toast, or modal appear.
8. Review executor console for uncaught errors and repeated warnings.

## Feature acceptance

Each feature memory file contains focused checks. A feature is not migrated merely because its control appears; enable, update, disable, respawn, reload, and unload paths must all be verified when relevant.
