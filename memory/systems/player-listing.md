# System memory: player listing

Keep the user flow: live join/leave updates, username/display-name search, sorting, selection, view, teleport, and fling actions.

Rework requirements: one player data service owns character/health/distance/avatar metadata; UI rows are virtualized or updated only when data changes; action availability is explicit; camera/view state restores on deselection and unload.

No row may own a heartbeat connection. The view uses shared list-row, button, icon, and empty-state components.

Executor checks: join/leave, respawn, search, every sort mode, select/deselect, view restore, teleport with missing root, and fling cleanup.

