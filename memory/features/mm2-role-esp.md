# Feature memory: MM2 role ESP

State: MM2 `Enabled`, `PlayerESP`.

Behavior: resolves murderer/sheriff/innocent from replicated attributes/values or held tools and applies role color highlight/label.

Rework status: the old private MM2 window is removed. The shared-theme MM2 controller exposes `Ana Sistem` and `Rol ESP` controls without constructing feature-specific windows. Role resolution/rendering remains engine-owned and preserves the existing replicated value/attribute/tool lookup plus 0.15-second update cadence.

Executor checks: launch from the catalog, enable the main system and role control, then verify each role, role change, hidden/late tool, join/leave, respawn, round transition, disable, window close/reopen, hub unload, and re-execution. Closing the view must not silently change feature state; disabling/unloading must remove all highlights and billboards.
