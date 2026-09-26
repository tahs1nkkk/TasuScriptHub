# System memory: search indexing

Keep the purpose: discover categories, feature controls, actions, and navigation targets from one query.

Rework requirements: index stable IDs plus normalized labels, aliases, category, description, and keywords; update incrementally when controls register/unregister; rank exact, prefix, token, and fuzzy matches predictably; never traverse raw UI descendants to build the index.

Activating a result opens the correct category, expands the owning section, focuses/highlights the control, and closes through the shared overlay coordinator.

The revision-3 game catalog has a deliberately local metadata search that filters by name, place ID, built-in ID, remote status, and remote feature summary before virtual cards are created. Hovering the search control reveals the 160 px clipped shell, a non-empty query pins it open, clearing and leaving it collapses it, and the input reserves a separate internal 48 px result-count zone. Search combines with the default unsupported-status filter, preserves status/alphabetic ordering, resets scroll to the first virtual page, and never traverses UI descendants. It does not replace, register into, or fork the future global search index; catalog registration remains a later service migration.

Executor checks: empty query, typo, alias, duplicate labels in different categories, dynamically loaded MM2 controls, removed controls, keyboard navigation, and mouse activation.
