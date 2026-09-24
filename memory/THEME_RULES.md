# Shared theme contract

Status: the rework uses a dark-gray, minimal, vector-first direction, three permanent UI colors, and one transient completion-state color. The complete component language is still being developed step by step.

## Core three-color palette and success state

- `Base` — RGB `18, 19, 22` / `#121316`: viewport canvas and deepest surfaces.
- `Layer` — RGB `37, 39, 45` / `#25272D`: tracks, raised surfaces, and inactive controls.
- `Signal` — RGB `242, 243, 245` / `#F2F3F5`: icon geometry, loader track, primary text, borders, and active states.
- `Success` — RGB `79, 224, 141` / `#4FE08D`: the sole approved exception, used only for confirmed successful completion feedback such as the loader's final status.
- New UI code cannot introduce another color. Outside the transient `Success` state, hierarchy is created with transparency, spacing, stroke weight, and typography.
- `TextOnAccent` resolves to `Base`; muted text resolves to `Signal` with transparency rather than a new gray.
- Runtime/game data colors such as health, team identity, ESP targets, and world effects remain the only exceptions because they communicate gameplay data rather than application theme.

## Approved loader direction

- The loader covers the entire viewport with a `Base` scrim at 0.20 transparency over a tracked Roblox `BlurEffect` at size 34. Background and blur enter over 0.5 seconds. Exit moves the complete loader downward over `1.7/3` seconds (approximately 0.567 seconds) with Quint-In acceleration while the blur returns to zero; the loader's complete visual tree fades uniformly over the same duration with linear easing.
- Loader content stays hidden until the background entry finishes. The icon, progress bar, and status text then fade and scale in, in that order, from 0.82 to a 1.035 overshoot over 0.26 seconds and settle to normal over 0.08 seconds. Progress cannot begin before all three reveals finish.
- The 280×280 reusable `TasuHub` icon occupies the middle area. Its sole visual source is the intentionally multicolor decal `138667112902223`. Because direct decal delivery requires authorization and `rbxthumb` did not resolve inside the executor UI, runtime code queries the Roblox thumbnail API, downloads the returned PNG, and registers it through the executor's custom-asset API. The former vector fallback is removed; a failed asset path leaves the fixed-size icon canvas empty without shifting layout. After its staged reveal, the icon stays fixed on its center anchor and runs a slow 6.4 second sine loop: rotation rocks between −6° and +6° while scale breathes continuously from 1 to 1.08. The 480×28 progress bar and 18 px status are positioned at 80% viewport height; the bottom-right version label retains its safe margin.
- The thin, fully rounded progress track/frame uses `Signal` white; its fill uses `Layer` gray. Both percentage layers use `Signal` white; the clipped duplicate remains synchronized with the fill without changing the requested white percentage color. Progress changes use a deliberately slower 1.4 second tween.
- The former top-edge glow/fade is removed. A responsive 60×22 vector dot grid starts at 40% viewport height and occupies the lower 60%. Its remembered baseline is `x=(column-0.5)/60`, `y=(row-0.5)/22`, size `round(2+v²×9)`, and transparency `0.98-v²×0.36`, where `v=(row-1)/21`. The grid loops upward at constant speed over 5.2 seconds per full travel; size and transparency continuously follow the remembered vertical curve. An 8% edge envelope brings opacity to exactly zero at both travel endpoints before wrapping, preventing the terminal-frame flash. It uses `Signal` only and remains behind all loader content.
- The loader uses no icon, bar, text, or background shadow objects. Depth comes only from blur, transparency, scale, and the lower dot grid.
- Progress changes tween smoothly. Runtime status changes immediately at actual construction boundaries and yield one scheduler frame, allowing short-lived code/system headings to render without adding artificial loading delays.
- At 100%, the progress bar shrinks toward its center and disappears silently over 0.7 seconds. The status then changes to green `Herşey Hazır!`, shifts upward from 80% to 76% viewport height, scales to 1.40 over 1.2 seconds, and plays the final completion pop. This completed state remains for 1.8 seconds before exit. No other content has an independent exit: the complete loader accelerates downward and fades linearly over approximately 0.567 seconds until it leaves the viewport; only then is it hidden and destroyed.
- Loader entry, each content pop-in, the final ready text, and the complete background exit use shared non-positional Roblox asset sounds through the central audio registry. The bar-collapse pop-out sound is forbidden. Exit uses soft UI transition asset `90657541635248` (`sfx_ui_whoosh_medsmall`) at volume 0.09. Its native two-second recording plays at `2/3` speed for a three-second duration, while a `PitchShiftSoundEffect` at octave 1.5 compensates the pitch drop so the modern character remains. It begins at the same instant as the downward exit. The previous reverse horror-like whoosh is forbidden. Missing or permission-restricted audio must never stop an animation.

## One theme, one source

- The application has exactly one active theme object and one semantic token registry.
- New features consume existing tokens. They cannot create a feature-specific palette, font set, corner-radius scale, shadow recipe, or animation style.
- Direct `Color3.fromRGB` values are forbidden in feature UI code. Colors are defined only in the theme registry, except runtime data colors such as health gradients, team colors, ESP target colors, and game-derived colors.
- Theme changes update bound components through one refresh path. Rebuilding an entire feature window to apply a theme is forbidden.
- A missing token is added to this contract only when it represents a reusable semantic role, never a single screen or feature.

## Approved post-loader corner actions

- The persistent action rail is anchored 24 px from the viewport's right and bottom edges and appears only after the full-screen loader has exited and been destroyed.
- It contains exactly two 60×60 square buttons in a vertical stack with a 12 px gap and 16 px corners. Both surfaces use 0.18 background transparency.
- The upper action uses `Base` with a `Signal` border. The lower action uses `Layer` with a `Base` border. This is deliberate contrast within the shared three-color system, not a private palette.
- Button icons are Roblox assets resolved through the shared executor thumbnail/custom-asset pipeline and occupy identical centered 30×30 `Fit` slots. The upper catalog icon is decal `137753054375497`; the lower general-menu icon is decal `83533116222028`. Their shared anchor, position, and slot size must remain symmetric even if the source images have different artwork bounds.
- Reveal fades the rail and brings each button from 0.88 to 1 scale over 0.34 seconds with an 0.08-second stagger. Hover scales only the hovered button from 1 to 1.07 over 0.22 seconds and plays the shared short UI-hover cue once on pointer entry. Press feedback briefly uses 0.96 scale.

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
- Motion is smooth and deliberately unhurried except for the intentionally responsive loader: controls 0.22–0.32 s, panels 0.45–0.65 s, modals 0.55–0.75 s, loader entry 0.5 s, progress 1.4 s, completion collapse 0.7 s, completion-status transition 1.2 s, and whole-loader downward exit approximately 0.567 s.
- Prefer position and `CanvasGroup.GroupTransparency` transitions. Do not animate layout-critical `Size` values when it can reflow or clip content.
- Do not hide or destroy content until its closing tween completes.
- `UIScale` is limited to subtle decorative emphasis in the 0.985–1.015 range. Approved exceptions are the loader's staged reveal (0.82 → 1.035 → 1), icon breathing loop (1 ↔ 1.08), completed bar collapse (1 → 0.02 before hiding), and final status emphasis (1 → 1.40), plus the corner actions' reveal (0.88 → 1), hover (1 → 1.07), and press (→ 0.96) feedback. These transitions do not participate in layout reflow.
- Re-entrant actions cancel or supersede the prior tween cleanly; overlapping tweens may not leave stale transparency, position, or input state.
- Reduced-motion support must be possible through a single global duration multiplier.

## Icons

- Icons come from one icon registry and are addressed by semantic names.
- Feature code requests an icon name; it does not own asset URLs.
- Interactive icons have a text fallback and inherit theme color unless the asset is intentionally multicolor. The decorative TasuHub loader mark is the approved exception: at the user's request it has no visual fallback and leaves its reserved canvas empty if loading fails.
- Missing or failed remote assets must not shift layout or remove the associated action.
- General icons live in the shared icon library and accept size/Z-index options, plus color where the source supports tinting. `TasuHub` is the first general icon and must be reused rather than redrawn in each location. Its approved multicolor asset preserves original colors and has no fallback geometry.

## Component rules

- Buttons, toggles, sliders, dropdowns, inputs, cards, tabs, search results, player rows, notifications, and modals each have one shared component implementation.
- Feature code composes components; it does not clone and restyle them.
- Focus, hover, pressed, disabled, selected, loading, success, warning, and error states are defined once per component.
- Z-index bands, clipping behavior, overlay ownership, and input capture are centralized.

## Change rule

Any proposed visual exception must first be expressed as a reusable token or component state in this file. If it cannot be generalized, it does not enter the UI.
