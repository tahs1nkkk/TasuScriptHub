# Feature memory: fling

State: `Fling`, `FlingMode`. User-facing fling power/speed settings are removed.

Behavior: walk, contact, or fly fling modes use one fixed strongest bounded profile while attempting to restore player position. Legacy pulse magnitude is fixed at 10,000,000 and fly speed at 300; config keys for the former sliders are cleared.

Rework: explicit target/session ownership, bounded physics values, anti-fling priority, guaranteed velocity reset, and clear unsupported-state reporting.

Executor checks: every mode, no target, target leave/death, local respawn, anti-fling interaction, fly controls, disable, and unload.

Main UI revision 2: fling mode/enable remain under `Misc` with no strength slider; player-row targeted fling is separately owned by `player_service.lua`. It locks camera display, hides the local avatar locally, snapshots/restores local root velocity/CFrame/collision/mass/humanoid/camera/transparency, suspends fly/orbit/legacy fling/static and moving anti-fling through loader ownership callbacks, applies one eight-Heartbeat predictive fixed-strength contact burst, and restores once after completion/cancellation. The former 36-pulse Stepped+Heartbeat+RenderStepped loop and periodic safe-position jumps are removed to prevent action latency and client stalls. It rejects anchored/dead/missing targets. Client network ownership means target movement is never guaranteed.

Executor checks additionally cover different rigs, target death/removal, local respawn, low ownership, every movement-system conflict, action replacement/unload, and exact camera/CFrame/velocity restoration.
