# Feature memory: MM2 role ESP

State: MM2 `Enabled`, `PlayerESP`.

Behavior: resolves murderer/sheriff/innocent from replicated attributes/values or held tools and applies role color highlight/label.

Rework: role resolver and renderer are separate; uncertainty is represented explicitly; shared TasuHub controls replace the MM2 window.

Executor checks: each role, role change, hidden/late tool, join/leave, respawn, round transition, disable, and unload.

