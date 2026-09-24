# System memory: script loading and catalog

Keep the user flow: built-in entries, saved entries, URL/source execution, edit/delete, banner lookup, and capability feedback.

Rework requirements: separate catalog data from its view; validate HTTPS URLs and source presence; return structured compile/runtime errors; version remote modules; prevent duplicate execution; preserve text/icon fallback when images fail.

The system consumes shared theme components and never constructs a private catalog palette or modal.

The upper post-loader corner button, using Roblox decal `137753054375497`, is the reserved future entrypoint for this catalog. Its catalog view is intentionally not implemented yet. In the current intermediate build only, the button invokes TasuHub unload; the eventual catalog work replaces that callback without changing the icon's semantic role or creating another launcher.

Executor checks: load built-in MM2 entry, load a saved source entry, exercise a bad URL, a compile error, and an executor without file APIs.
