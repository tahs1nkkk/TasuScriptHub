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

Phase 1 and the approved loader are complete. The action rail and catalog revision 10 remain in place. Main-menu revision 2 advances phases 4–7 with a versioned view, deterministic descriptors, nine English categories, fixed-geometry navigation, two-column collapsible cards, hierarchical search, real dropdowns, whole-window responsive scaling, offscreen-aware reopening, player virtualization/actions through `player_service.lua`, and a snapshot-only stats overlay. Lighting/RGB and freecam range revisions are implemented without changing compatibility flags. Legacy presentation stays disabled. Bytecode preflight passes; executor/visual acceptance remains pending before merge to `main` or physical deletion of remaining compatibility builders.
