# System memory: script loading and catalog

Keep the user flow: built-in entries, saved entries, URL/source execution, edit/delete, banner lookup, and capability feedback.

Rework requirements: separate catalog data from its view; validate HTTPS URLs and source presence; return structured compile/runtime errors; version remote modules; prevent duplicate execution; preserve text/icon fallback when images fail.

The system consumes shared theme components and never constructs a private catalog palette or modal.

Executor checks: load built-in MM2 entry, load a saved source entry, exercise a bad URL, a compile error, and an executor without file APIs.

