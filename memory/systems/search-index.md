# System memory: search indexing

Keep the purpose: discover categories, feature controls, actions, and navigation targets from one query.

Rework requirements: index stable IDs plus normalized labels, aliases, category, description, and keywords; update incrementally when controls register/unregister; rank exact, prefix, token, and fuzzy matches predictably; never traverse raw UI descendants to build the index.

Activating a result opens the correct category, expands the owning section, focuses/highlights the control, and closes through the shared overlay coordinator.

Executor checks: empty query, typo, alias, duplicate labels in different categories, dynamically loaded MM2 controls, removed controls, keyboard navigation, and mouse activation.

