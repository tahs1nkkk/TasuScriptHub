# Feature memory: fling

State: `Fling`, `FlingMode`, `FlingPower`, `FlingFlySpeed`.

Behavior: walk, contact, or fly fling modes pulse local assembly motion while attempting to restore player position.

Rework: explicit target/session ownership, bounded physics values, anti-fling priority, guaranteed velocity reset, and clear unsupported-state reporting.

Executor checks: every mode, no target, target leave/death, local respawn, anti-fling interaction, fly controls, disable, and unload.

Main UI revision 2: legacy fling controls remain available under `Misc`; player-row targeted fling is separately owned by `player_service.lua`. It locks camera display, snapshots/restores local root velocity/CFrame/humanoid/camera, suspends fly/orbit/legacy fling/anti-fling through loader ownership callbacks, applies bounded contact pulses, and restores after completion/cancellation. It rejects anchored/dead/missing targets. Client network ownership means target movement is never guaranteed.

Executor checks additionally cover different rigs, target death/removal, local respawn, low ownership, every movement-system conflict, action replacement/unload, and exact camera/CFrame/velocity restoration.
