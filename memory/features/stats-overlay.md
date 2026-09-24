# Feature memory: statistics overlay

State: `Stats.Visible`, `FPS`, `Ping`, `Players`, `Memory`.

Behavior: renders selected client metrics in a movable overlay.

Rework: shared overlay component, throttled sampling, missing-stat fallback, stable drag bounds, and shared theme/motion tokens.

Executor checks: every metric combination, unavailable ping/memory, resolution change, drag, hide/show, reload, and unload.

