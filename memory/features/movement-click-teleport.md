# Feature memory: click teleport

State: `ClickTP`.

Behavior: modifier plus click moves the local root to the selected world position.

Rework: central input binding, processed-input guard, valid ray target, safe character/root checks, and no activation while typing or using UI.

Executor checks: valid ground, sky/no target, UI click, text focus, missing root, respawn, rapid toggle, and unload.

