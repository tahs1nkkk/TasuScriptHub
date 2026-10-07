# Feature memory: statistics overlay

State: `Stats.Visible`, `FPS`, `Ping`, `Players`, `Memory`.

Behavior: renders selected client metrics in a movable overlay.

Rework: shared overlay component, throttled sampling, missing-stat fallback, stable drag bounds, and shared theme/motion tokens.

Executor checks: every metric combination, unavailable ping/memory, resolution change, drag, hide/show, reload, and unload.

Main UI revision 2: `Show Stats` is the first Home/Stats Overlay control. FPS, Ping, Player Count, and Memory rows are visible only while it is enabled. Loader's existing throttled sampler publishes immutable snapshots; the draggable shared-theme `Live Stats` view subscribes and owns no heartbeat. The dormant legacy panel remains forbidden.
