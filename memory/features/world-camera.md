# Feature memory: camera FOV and third person

State: `CameraFOV`, `ThirdPerson`.

Behavior: overrides current camera field of view and local zoom/camera constraints.

Rework: bind to camera replacement, capture originals per session, and restore only owned properties.

Executor checks: FOV limits, first/third-person games, camera replacement, respawn, game camera scripts, disable, and unload.

