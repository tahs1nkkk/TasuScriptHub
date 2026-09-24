# Feature memory: visual preview

Current behavior: legacy UI creates a viewport avatar and mirrors ESP options.

Rework decision: do not copy the implementation. Re-evaluate after theme selection; if retained, it becomes a shared preview component driven by feature state and lifecycle ownership.

Removal impact: `getBoundingScreenBox` may become dead when the legacy preview is removed.

Executor checks if retained: avatar clone failure, R6/R15, animations, panel open/close, category change, respawn, and unload.

