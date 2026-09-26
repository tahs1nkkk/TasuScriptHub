# System memory: search indexing

Keep the purpose: discover categories, feature controls, actions, and navigation targets from one query.

Rework requirements: index stable IDs plus normalized labels, aliases, category, description, and keywords; update incrementally when controls register/unregister; rank exact, prefix, token, and fuzzy matches predictably; never traverse raw UI descendants to build the index.

Activating a result opens the correct category, expands the owning section, focuses/highlights the control, and closes through the shared overlay coordinator.

The revision-2 game catalog has a deliberately local header search that filters its already-authorized card records by name, place ID, built-in ID, remote status, and remote feature summary. Hovering the search control reveals the clipped input, a non-empty query pins it open, clearing and leaving it collapses it, and its live result count stays directly to the input's right. It must not traverse UI descendants and does not replace, register into, or fork the future global search index. Catalog registration with the shared index remains a later service migration.

Executor checks: empty query, typo, alias, duplicate labels in different categories, dynamically loaded MM2 controls, removed controls, keyboard navigation, and mouse activation.
