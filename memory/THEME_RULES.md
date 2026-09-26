# Shared theme contract

Status: the rework uses a dark-gray, minimal, vector-first direction, three permanent UI colors, plus semantic success/warning/danger feedback colors. The complete component language is still being developed step by step.

## Core three-color palette and success state

- `Base` — RGB `18, 19, 22` / `#121316`: viewport canvas and deepest surfaces.
- `Layer` — RGB `37, 39, 45` / `#25272D`: tracks, raised surfaces, and inactive controls.
- `Signal` — RGB `242, 243, 245` / `#F2F3F5`: icon geometry, loader track, primary text, borders, and active states.
- `Success` — RGB `79, 224, 141` / `#4FE08D`: confirmed successful completion feedback such as the loader's final status or a completed catalog execution.
- `Warning` — RGB `245, 196, 81` / `#F5C451`: semantic hover/readiness emphasis and supported-state feedback only.
- `Danger` — RGB `239, 86, 92` / `#EF565C`: unsupported/error feedback only.
- New UI code cannot introduce another color. Outside semantic feedback states, hierarchy is created with transparency, spacing, stroke weight, and typography.
- `TextOnAccent` resolves to `Base`; muted text resolves to `Signal` with transparency rather than a new gray.
- Runtime/game data colors such as health, team identity, ESP targets, and world effects remain the only exceptions because they communicate gameplay data rather than application theme.

## Approved loader direction

- The loader covers the entire viewport with a `Base` scrim at 0.20 transparency over a tracked Roblox `BlurEffect` at size 34. Background and blur enter over 0.5 seconds. Exit moves the complete loader downward over `1.7/3` seconds (approximately 0.567 seconds) with Quint-In acceleration while the blur returns to zero; the loader's complete visual tree fades uniformly over the same duration with linear easing.
- Loader content stays hidden until the background entry finishes. The icon, progress bar, and status text then reveal in that order. The bar and status retain the 0.82 → 1.035 → 1 path over 0.26 + 0.08 seconds. The enlarged icon has a dedicated, stronger arrival: 0.58 → 1.16 over 0.34 seconds, then 1.16 → 1 over 0.12 seconds. Progress cannot begin before all three reveals finish.
- The 392×392 reusable `TasuHub` icon occupies the middle area after a 30% reduction from the former 560 px size. Its sole visual source is the intentionally multicolor decal `138667112902223`. Because direct decal delivery requires authorization and `rbxthumb` did not resolve inside the executor UI, runtime code queries the Roblox thumbnail API, downloads the returned PNG, and registers it through the executor's custom-asset API. The loader remains completely invisible and silent until this required asset resolves; it retries up to 20 times at 0.5-second intervals and aborts with cleanup instead of revealing an empty canvas if the capability path never succeeds. After its staged reveal, the icon stays fixed on its center anchor and runs a smooth `6.4/1.5` second sine loop: rotation rocks between −6° and +6° while scale breathes continuously from 1 to 1.08. The 480×28 progress bar and 18 px status are positioned at 80% viewport height; the bottom-right version label retains its safe margin.
- The thin, fully rounded progress track/frame uses `Signal` white; its fill uses `Layer` gray. Both percentage layers use `Signal` white; the clipped duplicate remains synchronized with the fill without changing the requested white percentage color. The complete range is divided into exactly 30 equal checkpoints (`1/30` each). Every checkpoint animates over 0.14 seconds with a minimum 0.085-second interval before the next step, capping the visible/audio sequence at approximately 11.76 checkpoints per second while still permitting slower runtime-bound progress.
- Runtime construction milestones remain the source of target progress and status headings. Each milestone waits while a single sequential worker reaches its quantized target; values below 100% can target at most checkpoint 29, and checkpoint 30 is released only by the explicit final `SetLoading(1)`. This preserves real build ordering while intentionally pacing the 30 visible/audio steps.
- Every checkpoint plays the short `RBLX UI Hover 02` tick (`10066936758`) at volume 0.09. Playback speed interpolates linearly from 0.50 on checkpoint 1 to 1.42 on checkpoint 30, creating a more pronounced low/thick-to-high/bright rise. Checkpoint sounds use a dedicated 0.8-second cleanup window and may not replace or duplicate the final ready pop.
- The former top-edge glow/fade is removed. A responsive 60×22 vector dot grid starts at 44% viewport height and occupies the lower 56%, shifting its largest starting rows farther below the screen center. Its remembered baseline is `x=(column-0.5)/60`, `y=(row-0.5)/22`, size `round(2+v²×9)`, and transparency `0.98-v²×0.36`, where `v=(row-1)/21`. The grid loops upward at constant speed over 5.2 seconds per full travel; size and transparency continuously follow the remembered vertical curve. An 8% edge envelope brings opacity to exactly zero at both travel endpoints before wrapping, preventing the terminal-frame flash. It uses `Signal` only and remains behind all loader content.
- The loader uses no icon, bar, text, or background shadow objects. Depth comes only from blur, transparency, scale, and the lower dot grid.
- Progress changes pass through the sequential 30-checkpoint worker. Runtime status changes immediately at actual construction boundaries and remains visible while that boundary's checkpoint target is reached; the deliberate pacing is part of the requested live-loading feedback rather than a fabricated status source.
- At 100%, the progress bar shrinks toward its center and disappears silently over 0.7 seconds. The status then switches to Nunito Black (`Heavy`), changes to green `Herşey Hazır!`, shifts upward from 80% to 76% viewport height, and scales to 2.10 over 1.2 seconds—exactly 1.5× its preceding 1.40 completed-state scale—while playing the sole final completion pop at playback speed 0.60. This completed state remains for 1.8 seconds before exit. No other content has an independent exit: the complete loader accelerates downward and fades linearly over approximately 0.567 seconds until it leaves the viewport; only then is it hidden and destroyed.
- Loader entry, each content pop-in, the final ready text, and the complete background exit use shared non-positional Roblox asset sounds through the central audio registry. The bar-collapse pop-out sound is forbidden. Exit uses soft UI transition asset `90657541635248` (`sfx_ui_whoosh_medsmall`) at volume 0.09. Its native two-second recording plays at `2/3` speed for a three-second duration, while a `PitchShiftSoundEffect` at octave 1.5 compensates the pitch drop so the modern character remains. It begins at the same instant as the downward exit. The previous reverse horror-like whoosh is forbidden. Missing or permission-restricted audio must never stop an animation.

## One theme, one source

- The application has exactly one active theme object and one semantic token registry.
- New features consume existing tokens. They cannot create a feature-specific palette, font set, corner-radius scale, shadow recipe, or animation style.
- Direct `Color3.fromRGB` values are forbidden in feature UI code. Colors are defined only in the theme registry, except runtime data colors such as health gradients, team colors, ESP target colors, and game-derived colors.
- Theme changes update bound components through one refresh path. Rebuilding an entire feature window to apply a theme is forbidden.
- A missing token is added to this contract only when it represents a reusable semantic role, never a single screen or feature.

## Approved post-loader corner actions

- The persistent action rail appears only after the full-screen loader has exited and been destroyed. It is an edge dock: dragging chooses the nearest of `Left`, `Right`, `Top`, or `Bottom`, then constrains travel to that screen edge with an 8 px along-edge margin. It can never remain in the viewport center or be dragged beyond the viewport.
- It contains exactly two 70×70 square buttons in fixed absolute positions with an 18 px normal-state gap and 16 px corners. No automatic list/grid layout may control their positions. Both buttons use the same `Layer` surface, `Base` 6 px outline, and 0.18 background transparency.
- Button icons are Roblox assets resolved through the shared executor thumbnail/custom-asset pipeline and occupy identical centered 48×48 `Fit` slots. The upper catalog icon is decal `137753054375497`; the lower general-menu icon is decal `83533116222028`. Their shared anchor, position, and slot size must remain symmetric even if the source images have different artwork bounds.
- Reveal fades the complete rail over 0.34 seconds without altering button geometry. Hover animates the hovered button's actual `Size` from 70×70 to 76×76 and its icon from 48×48 to 52×52 over 0.22 seconds; press feedback uses 67×67 with a 46×46 icon. The button and its content therefore grow together without `UIScale` or moving the neighboring button.
- Every rail container has clipping disabled. The stack reserves the complete hover bounds plus an 8 px safety pad on each side (`6 px stroke + 2 px`), preventing the thick outline or growing content from being cropped by an invisible parent.
- The original hover audio `113397864512278` is now the button click cue. Hover uses Roblox's short `RBLX UI Hover 02` tick (`10066936758`). The edge visibility bar is silent for hover and activation.
- The visibility control is a compact 18×64 rounded bar fixed flush to a left/right edge; it rotates its geometry to 64×18 when docked to top/bottom. It shares the buttons' `Layer` surface at 0.18 transparency, uses a 2 px `Base` outline, and displays one centered `Signal` direction arrow. On left/right edges the open state points outward with `<`/`>` and the hidden state points inward; top/bottom use the corresponding rotated up/down direction. Dragging to another edge updates the arrow immediately, while toggling animates its rotation. On vertical edges the bar sits 16 px above the button stack's center. The separate button stack slides and fades beyond the active edge over 0.44 seconds while this bar stays attached and clickable. The hidden stack becomes non-visible only after its exit tween completes.

## Required semantic tokens

- Surfaces: `Canvas`, `Surface`, `SurfaceRaised`, `SurfaceOverlay`, `ControlIdle`, `ControlHover`, `ControlPressed`.
- Borders and depth: `BorderSubtle`, `BorderStrong`, `Shadow`, `Scrim`.
- Text: `TextPrimary`, `TextSecondary`, `TextMuted`, `TextOnAccent`.
- Intent: `Accent`, `AccentHover`, `Success`, `Warning`, `Danger`, `Info`.
- Typography: `Heading`, `Body`, `Label`, `Mono`; sizes come from one type scale.
- Shape: `RadiusSmall`, `RadiusMedium`, `RadiusLarge`, `StrokeThin`, `StrokeStrong`.
- Spacing: a shared 4-based spacing scale; arbitrary padding is forbidden.
- Motion: `MotionFast`, `MotionControl`, `MotionPanel`, `MotionModal`, `MotionLoader`, the catalog pull/content/search tokens, and shared easing tokens.

## Approved game-catalog window — revision 2

- The upper corner action opens one movable popup supplied by the versioned remote `game_catalog.lua` module. The module receives shared theme, layout, motion, input, audio, and lifecycle services; it may not define a private palette or expose legacy UI.
- The responsive window is capped at 780×520 px with a 14 px viewport inset, 20 px outer radius, and 2 px `Base` outline. Its 60 px header and 42 px footer are fully opaque `Base`. The middle body uses `Layer` at exactly 0.20 background transparency. Header and footer drag zones move the window while clamping the complete window to the viewport.
- The header title `Oyun Kataloğu` remains centered. A 40×40 vector search control sits on the right, with a 40×40 `×` close control immediately to its right. Hover reveals a clipped 220×36 input to the left; the live result count is placed directly to that input's right. A non-empty query pins the input open, while an empty unfocused/unhovered input collapses without leaking placeholder text outside its bounds.
- The body contains a vertically scrolling, centered three-column grid. Cards use a 142 px cropped automatic game cover with a 26 px status strip overlaid inside its bottom edge, a larger title, and one compact centered-dot feature line. No run hint or explanatory footer copy is allowed.
- Official status and feedback colors are semantic: `Stable`/successful execution uses `Success`, `Supported` uses `Warning`, and `Un-Supported`/execution failure uses `Danger`. Hover slowly raises an outward `Warning` outline; failed activation replaces it with `Danger`, shakes the card, and raises a bottom-center reason toast. Successful activation uses the same path with `Success` and no failure shake.
- The remote module appends five non-executable preview cards with automatic real-game covers so the three-column layout can be evaluated before those scripts exist. Their names, place IDs, statuses, and feature summaries are remote-owned; selecting one reports why it cannot run rather than calling the loader execution service.
- Game covers resolve automatically from `PlaceId` to Roblox `UniverseId`, then through the official 768×432 game-thumbnail endpoint and executor custom-asset cache. A name-based vector/text fallback remains in place if resolution fails; cover failure cannot shift the card.
- Status authority lives only inside the remotely loaded module. Local catalog `Status` fields are ignored, the remote status map and copied card entries are frozen, and no status setter is exported. This prevents loaded catalog scripts from changing the official UI status through the supported runtime contract; it is not a claim that client-side executor code is cryptographically tamper-proof.
- Opening places the already-final-size window at the upper corner button's current center, then moves it to its saved resting center while one `UIScale` grows the complete visual tree from 0 to 1 over 0.52 seconds. Closing samples the button again, moves back to that point, and scales the complete tree from 1 to exactly 0 over 0.44 seconds before hiding it. No layout-critical `Size` is animated, so header, body, grid, and text never reflow during either transition. Transition revisions cancel stale completions.

## Motion rules

- Every open, close, expand, collapse, category change, modal, dropdown, tooltip, and drag-settle action uses shared motion tokens.
- Motion is smooth and deliberately unhurried except for the intentionally responsive loader: controls 0.22–0.32 s, panels 0.45–0.65 s, modals 0.55–0.75 s, loader entry 0.5 s, each of 30 progress steps 0.14 s with a minimum 0.085 s interval, completion collapse 0.7 s, completion-status transition 1.2 s, and whole-loader downward exit approximately 0.567 s.
- Prefer position and `CanvasGroup.GroupTransparency` transitions. Do not animate layout-critical `Size` values when it can reflow or clip content. The catalog transition keeps its final window size throughout and combines position with whole-window scale.
- Do not hide or destroy content until its closing tween completes.
- `UIScale` is limited to subtle decorative emphasis in the 0.985–1.015 range. Approved exceptions are the loader bar/status reveal (0.82 → 1.035 → 1), the larger icon arrival (0.58 → 1.16 → 1), icon breathing loop (1 ↔ 1.08), completed bar collapse (1 → 0.02 before hiding), final status emphasis (1 → 2.10), and the catalog's whole-window 0 ↔ 1 origin transition. Corner-action hover and press feedback deliberately animate the fixed-position button and icon `Size` values together; their padded parent bounds and clipping rules reserve the maximum geometry so no neighboring layout reflows.
- Re-entrant actions cancel or supersede the prior tween cleanly; overlapping tweens may not leave stale transparency, position, or input state.
- Reduced-motion support must be possible through a single global duration multiplier.

## Icons

- Icons come from one icon registry and are addressed by semantic names.
- Feature code requests an icon name; it does not own asset URLs.
- Interactive icons have a text fallback and inherit theme color unless the asset is intentionally multicolor. The decorative TasuHub loader mark is the approved exception: it has no visual fallback and is a hard loader prerequisite, so the loader waits off-screen and aborts cleanly if the asset cannot resolve.
- Missing or failed remote assets must not shift layout or remove the associated action.
- General icons live in the shared icon library and accept size/Z-index options, plus color where the source supports tinting. `TasuHub` is the first general icon and must be reused rather than redrawn in each location. Its approved multicolor asset preserves original colors and has no fallback geometry.

## Component rules

- Buttons, toggles, sliders, dropdowns, inputs, cards, tabs, search results, player rows, notifications, and modals each have one shared component implementation.
- Feature code composes components; it does not clone and restyle them.
- Focus, hover, pressed, disabled, selected, loading, success, warning, and error states are defined once per component.
- Z-index bands, clipping behavior, overlay ownership, and input capture are centralized.

## Change rule

Any proposed visual exception must first be expressed as a reusable token or component state in this file. If it cannot be generalized, it does not enter the UI.
