# Shared theme contract

Status: the rework uses a dark-gray, minimal, vector-first direction and exactly three approved UI colors. The complete component language is still being developed step by step.

## Fixed three-color palette

- `Base` — RGB `18, 19, 22` / `#121316`: viewport canvas and deepest surfaces.
- `Layer` — RGB `37, 39, 45` / `#25272D`: tracks, raised surfaces, and inactive controls.
- `Signal` — RGB `242, 243, 245` / `#F2F3F5`: icon geometry, progress fill, primary text, borders, and active states.
- New UI code cannot introduce a fourth color. Hierarchy is created with transparency, spacing, stroke weight, and typography.
- `TextOnAccent` resolves to `Base`; muted text resolves to `Signal` with transparency rather than a new gray.
- Runtime/game data colors such as health, team identity, ESP targets, and world effects remain the only exceptions because they communicate gameplay data rather than application theme.

## Approved loader direction

- The loader covers the entire viewport with the dark-gray `Base` color. Background entry and exit use the same 1.65 second Quint fade duration.
- Loader content stays hidden until the background entry finishes. The icon, progress bar, and status text then fade and scale in, in that order, through a small-to-1.035 overshoot and a short settle to normal scale. Progress cannot begin before all three reveals finish.
- The center composition contains the reusable vector `TasuHub` icon, one horizontal progress bar, an in-bar percentage, and one live status line below it.
- The thin, fully rounded progress track uses `Layer`; its fill uses `Signal`. Percentage text is duplicated and clipped so it appears `Signal` on the unfilled track and `Base` over the filled area, producing a true negative/inverted effect.
- The loader has no card, gradient, shadow, illustration, radial spinner, decorative particle, or unnecessary detail.
- Progress changes tween smoothly; status changes fade in without resizing the layout.
- Completion shows `TasuHub hazır`. Icon, progress bar, and status text then accelerate upward with Quint-In motion in that order, starting exactly 0.6 seconds apart. The background fade starts as soon as the status text begins moving and finishes with the final slide.

## One theme, one source

- The application has exactly one active theme object and one semantic token registry.
- New features consume existing tokens. They cannot create a feature-specific palette, font set, corner-radius scale, shadow recipe, or animation style.
- Direct `Color3.fromRGB` values are forbidden in feature UI code. Colors are defined only in the theme registry, except runtime data colors such as health gradients, team colors, ESP target colors, and game-derived colors.
- Theme changes update bound components through one refresh path. Rebuilding an entire feature window to apply a theme is forbidden.
- A missing token is added to this contract only when it represents a reusable semantic role, never a single screen or feature.

## Required semantic tokens

- Surfaces: `Canvas`, `Surface`, `SurfaceRaised`, `SurfaceOverlay`, `ControlIdle`, `ControlHover`, `ControlPressed`.
- Borders and depth: `BorderSubtle`, `BorderStrong`, `Shadow`, `Scrim`.
- Text: `TextPrimary`, `TextSecondary`, `TextMuted`, `TextOnAccent`.
- Intent: `Accent`, `AccentHover`, `Success`, `Warning`, `Danger`, `Info`.
- Typography: `Heading`, `Body`, `Label`, `Mono`; sizes come from one type scale.
- Shape: `RadiusSmall`, `RadiusMedium`, `RadiusLarge`, `StrokeThin`, `StrokeStrong`.
- Spacing: a shared 4-based spacing scale; arbitrary padding is forbidden.
- Motion: `MotionFast`, `MotionControl`, `MotionPanel`, `MotionModal`, `MotionLoader` and shared easing tokens.

## Motion rules

- Every open, close, expand, collapse, category change, modal, dropdown, tooltip, and drag-settle action uses shared motion tokens.
- Motion is smooth and deliberately unhurried: controls 0.22–0.32 s, panels 0.45–0.65 s, modals 0.55–0.75 s, loader entry/exit 1.65 s.
- Prefer position and `CanvasGroup.GroupTransparency` transitions. Do not animate layout-critical `Size` values when it can reflow or clip content.
- Do not hide or destroy content until its closing tween completes.
- `UIScale` is limited to subtle decorative emphasis in the 0.985–1.015 range. The loader's approved staged reveal is the sole exception: it starts at 0.82, reaches 1.035, and settles at 1 without changing layout size. Never scale text/content to zero and never combine scale animation with layout resizing.
- Re-entrant actions cancel or supersede the prior tween cleanly; overlapping tweens may not leave stale transparency, position, or input state.
- Reduced-motion support must be possible through a single global duration multiplier.

## Icons

- Icons come from one icon registry and are addressed by semantic names.
- Feature code requests an icon name; it does not own asset URLs.
- Every icon has a text fallback and inherits theme color unless the asset is intentionally multicolor.
- Missing or failed remote assets must not shift layout or remove the associated action.
- General icons live in the shared vector icon library and accept size/color/Z-index options. `TasuHub` is the first general icon and must be reused rather than redrawn in each location.

## Component rules

- Buttons, toggles, sliders, dropdowns, inputs, cards, tabs, search results, player rows, notifications, and modals each have one shared component implementation.
- Feature code composes components; it does not clone and restyle them.
- Focus, hover, pressed, disabled, selected, loading, success, warning, and error states are defined once per component.
- Z-index bands, clipping behavior, overlay ownership, and input capture are centralized.

## Change rule

Any proposed visual exception must first be expressed as a reusable token or component state in this file. If it cannot be generalized, it does not enter the UI.
