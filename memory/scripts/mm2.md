# Script memory: mm2.lua

Role: Murder Mystery 2 catalog module with role ESP, gun-drop ESP, automatic pickup, automatic fire, and manual pickup/fire actions.

Current shape: the feature state/loops remain self-contained, but the old separate `TasuHubMM2` `ScreenGui` and private blue UI are removed. `mm2.lua` now requires the loader's frozen shared game-window context, mounts one `MM2GameRoot` below `InterfaceRoot`, returns the controller, and also publishes it as `env.TasuHubMM2` for compatibility.

Controller contract: `GetState`, `SetState`, `Enable`, `Disable`, `RefreshCharacter`, `Open`, `Close`, `Toggle`, `IsOpen`, `Destroy`, and `Unload`. The loader owns catalog execution, controller registration, the square game-icon rail button, automatic first open, and hub-level destruction. MM2 owns only its feature runtime and smaller 620×420 responsive view.

Revision-1 UI: shared `Base`/`Layer`/`Signal` palette and semantic feedback, shared Nunito/BuilderSans fonts, opaque 56 px header and 38 px footer, 20%-transparent body, responsive two-column controls, full non-interactive header/footer drag, viewport clamp, and 0.48/0.40-second origin motion from the MM2 rail button. It exposes the existing five toggles and two manual actions without changing their default state or feature implementation.

Preserved runtime: replicated/tool role resolution, player role highlight/name, `GunDrop` descendant scan/highlight, prompt/touch pickup, gun remote fire discovery, murderer target validation, 0.15-second heartbeat cadence, player removal cleanup, and full unload teardown. Gameplay-data colors remain the only direct color values.

Do not assume remote names or events remain stable. Role resolution and gun/action discovery must fail safely and report unsupported game state. Direct standalone execution without a live shared TasuHub context is intentionally rejected; supported execution is the executor-loaded catalog path.

Runtime validation follows `../EXECUTOR_TESTING.md`; MM2 checks live under `../features/mm2-*`.
