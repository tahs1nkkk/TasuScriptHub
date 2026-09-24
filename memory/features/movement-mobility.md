# Feature memory: infinite jump and bunny hop

State: `InfiniteJump`, `BunnyHop`.

Behavior: responds to jump input and movement state for repeated jumping.

Rework: isolate input listeners, avoid duplicate jump requests, respect text focus/processed input, and reset cleanly on character change.

Executor checks: each feature alone/together, chat/text focus, grounded/airborne, respawn, rapid toggle, and unload.

