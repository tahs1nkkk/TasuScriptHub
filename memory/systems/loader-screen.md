# System memory: full-screen loader

Status: first reworked UI system implemented.

## Approved behavior

- A `Base` dark-gray full-screen `Frame` covers the complete viewport and ignores the Roblox inset through the parent `ScreenGui`; the fixed center content uses its own `CanvasGroup`.
- Entry uses synchronized 1.65 second Quint background/content fades. Completion holds for 0.95 seconds, then exits through the same synchronized fade before destruction.
- The centered layout is fixed and minimal: reusable vector `TasuHub` mark, 340×18 fully rounded horizontal track, percentage inside the bar, and a live status line below.
- Progress fill uses a slow 0.85 second Quint size tween. Layout dimensions do not animate.
- Percentage uses two synchronized labels: light text on the dark track and dark text clipped by the light fill.
- Status updates set new text and fade to the shared muted transparency over 0.42 seconds without moving or resizing content.
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

Run the canonical executor entrypoint on a fresh client and on a second execution. Confirm complete dark-gray coverage, deliberately slow entry/exit, centered icon at different resolutions, thin fully rounded track, monotonic fill, synchronized/inverted percentage text, live status changes, no remaining overlay, no legacy UI appearing afterward, and no duplicate loader after reload. Review the executor console for property/tween errors.
