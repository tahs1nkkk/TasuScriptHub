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
7. Exercise main-menu revision 2 through corner slot 2. Confirm no footer and catalog/main mutual exclusion. Cycle the 230→72 px rail at least 20 times and verify no button/text/icon jitter or stale tween. Test all ten categories, numeric/`rbxassetid://`/HTTPS category and player-action icons plus glyph fallback, two-column balancing, single-section full-width/two-control-column behavior, default-open cards, rotated `<` collapse state, persistence, and the old-page exit → 0.22-second gap → new-page entry order. Validate category/section/control search hierarchy, deterministic order, result count, auto-expand/scroll/three negative-color pulses, and input clear/close. Validate real dropdown ownership, outside dismissal, and every toggle bind. Verify Home loader-duration color thresholds; hold long enough to see the grid loop seamlessly upper-right, release at several progress points and confirm smooth cancellation; then hold for two seconds and confirm one unload. Test whole-window proportional scaling, unrestricted offscreen drag, close/reopen above/below 50% visible area, rapid reversals, and unload mid-animation. Exercise Stats conditional rows/overlay drag/snapshots and Players join/leave/search/sort/virtual rows/icon states/View/TP/Walk/Stop/arrival/live repath/blocked path/fast eight-frame Fling/local invisibility/complete restore. Test R6/R15 real 3D ESP boxes through walls, accessory exclusion, fill, box-attached health, projection alignment, arrows, global UI-over-visual layering, and unload with ESP active. Confirm Orbit player and mode lists are populated before enabling. Test doubled freecam mouse-look coefficient and teleport. Save a favorite and theme, fully unload/re-execute, and confirm both restore from `TasuHub/preferences_v1.json` while loading/resetting a normal config does not alter them. Test both anti-fling modes, third-person visibility restore, flat-texture restore, Atmosphere fog restore, fixed fling modes, and per-experience Waypoints config. At no point may a legacy surface appear.
8. Review executor console for uncaught errors and repeated warnings.
9. On a cleared executor asset cache, confirm no loader sound is delayed, both base rail icons resolve before ready or remain hidden for the whole session, and cached remote sources are not fetched twice by consumers. Open catalog/MM2, drag each fully outside, close/reopen, and verify the 50% recenter boundary. In MM2 test ESP/AIM/FARM transitions, collapsed navigation, banner stretch/softening/tint, all role chams and slow pulse, cards, general-ESP arbitration, Shoot Now, visibility-gated Auto Fire, underground collection, five-failure stop, role-based finish, respawn restore, and unload cleanup.

## Feature acceptance

Each feature memory file contains focused checks. A feature is not migrated merely because its control appears; enable, update, disable, respawn, reload, and unload paths must all be verified when relevant.
