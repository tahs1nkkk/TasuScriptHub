# Feature memory: Aim FOV

State: `FOV`, `ShowFOV`; color may follow shared/world RGB state.

Behavior: constrains selection radius and optionally renders the FOV circle around executor mouse coordinates.

Rework: FOV rendering becomes a feature overlay, not part of the application window; it consumes runtime visual tokens without creating a UI theme.

Executor checks: different resolutions/insets, visible/hidden, radius limits, RGB on/off, UI open/closed, and unload cleanup.

Main UI revision 1: registered FOV controls are descriptor-backed rows in `Nişan`; overlay ownership is unchanged. Verify slider/toggle updates and search navigation.
