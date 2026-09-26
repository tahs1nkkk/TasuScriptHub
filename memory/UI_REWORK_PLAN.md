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

Phase 1 and the user-approved loader are complete. The phase-3 action rail now supports its two base controls plus loader-owned dynamic game actions. The first phase-5 service/view migration has a revision-6 game catalog delivered through a versioned remote module: immediate motion, lightweight opening overlay, one fresh 3×3 content generation per open, complete closed-state release, late-cover rejection, full non-interactive header/footer dragging, compact internal-count search, default supported-only filtering, deterministic status/alphabetic order, equal padded cards, clipped lower-corner status strips, and compact feedback. MM2 is the first phase-7 game migration: its old standalone visual shell is removed, all existing engines remain, and one smaller shared-theme controller window is registered with the rail. Catalog success closes the catalog and opens that game view automatically. Executor and visual acceptance remain pending. All other legacy presentation stays disabled while remaining feature engines and state continue to operate.
