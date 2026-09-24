# TasuHub project rules

Before changing runtime code, read `memory/README.md` and every memory file linked for the system or feature being changed.

Non-negotiable rules:

- Runtime behavior is validated only in an executor. Roblox Studio is not a supported runtime or test target.
- `memory/THEME_RULES.md` is the single UI/theme contract. A feature must never introduce a private palette, typography set, animation language, or one-off theme.
- Keep the executor-verified build usable until its replacement is ready. Remove the legacy UI atomically when the new shell and its retained systems are ready.
- Feature engines and UI composition must remain separate. UI controls call feature controllers; feature loops must not construct feature-specific windows.
- Update the relevant feature memory file whenever behavior, state, dependencies, cleanup, or executor test coverage changes.
- Run the dead-code audit after each feature migration and record the result in `memory/DEAD_CODE_AUDIT.md`.

