# Script memory: ui_runtime.lua

Role: version-1 shared presentation runtime. It owns the common corner, outline, surface, label, button, animation, connection, and lifecycle-scope primitives consumed by catalog, main menu, and game views.

The runtime receives only the shared theme/font/motion services. It defines no feature palette, gameplay loop, Studio path, or independent input router. Scopes invalidate revisions, disconnect owned connections, and destroy explicitly scoped instances. Ordinary component instances are parent-owned by their controller root; the shared runtime deliberately keeps no strong global instance list, so catalog virtualization cannot accumulate destroyed-card references.

Current migration uses the runtime for all three visible controller shells' round/outline primitives and the catalog Auto-run button. Additional component migrations must extend this runtime rather than copy helpers into feature files.
