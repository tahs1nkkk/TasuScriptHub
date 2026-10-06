# UI rework plan

## Keep behavior, replace implementation

The current visual tree is not a design reference implementation. All legacy UI instances and component builders will be removed after the replacement shell exists.

Three systems retain their product purpose but receive new implementations:

- Script loading/catalog system.
- Player listing and player actions system.
- Search indexing and command discovery system.

They must not be copied line-for-line or visually reproduced. Their data contracts and successful user flows are preserved, then rebuilt against the new architecture and shared theme.

## Ordered migration

1. Lock memory, executor rules, and dead-code baseline.
2. Decide the visual reference and fill the semantic theme tokens.
3. Build theme, motion, icon, lifecycle, and shared component foundations.
4. Build an empty shell with navigation, overlays, notifications, and responsive bounds.
5. Rework search index, player directory, and catalog as shared services.
6. Re-register current categories and controls from feature descriptors.
7. Migrate feature controllers one family at a time and run executor acceptance checks.
8. Remove the entire legacy UI construction path and preview-only helpers.
9. Run dead-code audit, reload/unload checks, and complete executor regression.

## Current state

Phase 1 and the user-approved loader are complete. The phase-3 action rail supports both base controls plus loader-owned dynamic game actions. The phase-5 catalog remains at revision 10. Main-menu revision 1 begins the phase-4/6 shell migration through a versioned remote controller: slot 2 opens a same-size header-only window, default-expanded/collapsible icon category rail, descriptor-indexed search, and one reconstructed feature page at a time. Existing controllers remain the behavior source while their visible controls are recreated against shared tokens; legacy presentation stays disabled. MM2 remains the first phase-7 game migration. Executor and visual acceptance remain pending before further control/detail revisions or merge to `main`.
