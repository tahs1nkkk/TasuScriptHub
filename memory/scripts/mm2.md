# Script memory: mm2.lua

Role: Murder Mystery 2 catalog module with role ESP, gun-drop ESP, automatic pickup, automatic fire, and manual pickup/fire actions.

Current shape: self-contained state, feature loops, lifecycle, and a separate `TasuHubMM2` window.

Rework target: remove the separate visual shell. Expose MM2 feature descriptors and controller methods to the shared TasuHub UI while retaining independent cleanup and game-specific capability checks.

Do not assume remote names or events remain stable. Role resolution and gun/action discovery must fail safely and report unsupported game state.

Runtime validation follows `../EXECUTOR_TESTING.md`; MM2 checks live under `../features/mm2-*`.

