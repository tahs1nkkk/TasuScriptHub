# System memory: full-screen loader

Status: first reworked UI system implemented.

## Approved behavior

- A `Base` dark-gray full-screen `Frame` covers the complete viewport and ignores the Roblox inset through the parent `ScreenGui`; the fixed center content uses its own `CanvasGroup`.
- The empty `Base` background fades in over 1.65 seconds. The entry and exit background fades always use the same duration.
- Only after the background entry completes, icon, progress bar, and status text reveal sequentially. Each fades in while starting at 0.82 scale, grows to 1.035 over 0.52 seconds, and settles to 1 over 0.18 seconds before the next item appears.
- Progress begins only after all three reveal animations complete.
- The centered layout is fixed and minimal: reusable vector `TasuHub` mark, 340×18 fully rounded horizontal track, percentage inside the bar, and a live status line below.
- Progress fill uses a slow 0.85 second Quint size tween. Layout dimensions do not animate.
- Percentage uses two synchronized labels: light text on the dark track and dark text clipped by the light fill.
- Status updates set new text and fade to the shared muted transparency over 0.42 seconds without moving or resizing content.
- Completion holds for 0.95 seconds. Icon, bar, and status then slide beyond the top of the viewport with 1.65 second Quint-In acceleration, starting 0.6 seconds apart. The 1.65 second background exit fade starts immediately after the status slide starts.
- All loader visuals use only `Base`, `Layer`, and `Signal` from `THEME_RULES.md`.

## Shared icon contract

`UI.IconLibrary.TasuHub` constructs the mark from scalable Roblox frames. `UI.CreateIcon(parent, "TasuHub", options)` accepts `Size`, `Color`, and `ZIndex`, so the same geometry can be reused at different sizes without remote assets.

## Milestones

- 6% — `Arayüz hazırlanıyor`
- 22% — `Arayüz bileşenleri yükleniyor`
- 44% — `Özellikler hazırlanıyor`
- 70% — `Kategoriler oluşturuluyor`
- 90% — `Son kontroller yapılıyor`
- 100% — `TasuHub hazır`

## Executor acceptance

Run the canonical executor entrypoint on a fresh client and on a second execution. Confirm the background finishes fading before any content appears; icon, bar, and status pop in sequentially with a small overshoot; progress remains at zero until those reveals finish; the progress is monotonic; percentage inversion stays synchronized; and completion sends icon, bar, and status upward at exact 0.6 second start intervals with visible acceleration. Confirm the exit fade begins with the third slide, uses the same duration as entry, leaves no overlay, reveals no legacy UI, and creates no duplicate loader after reload. Review the executor console for property/tween errors.
