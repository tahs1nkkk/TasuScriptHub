# Feature memory: camera FOV and third person

State: `CameraFOV`, `ThirdPerson`.

Behavior: overrides current camera field of view and local zoom/camera constraints.

Rework: bind to camera replacement, capture originals per session, and restore only owned properties.

Executor checks: FOV limits, first/third-person games, camera replacement, respawn, game camera scripts, disable, and unload.

Main UI revision 2: camera/freecam controls remain stable `World` descriptors. Verify external camera replacement, responsive UI, and page close/reopen.

Improvement pass: while forced third person is active, every local character `BasePart.LocalTransparencyModifier` is snapshotted and forced to zero. Disable, freecam takeover, respawn, and unload restore the exact prior modifiers.
