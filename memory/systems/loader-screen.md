# System memory: full-screen loader

Status: first reworked UI system implemented.

## Approved behavior

- A `Base` dark-gray full-screen `Frame` covers the complete viewport and ignores the Roblox inset through the parent `ScreenGui`; the fixed center content uses its own `CanvasGroup`.
- The empty `Base` background fades in over 0.8 seconds. Entry and exit background fades always use the same duration.
- Only after the background entry completes, icon, progress bar, and status text reveal sequentially. Each fades in while starting at 0.82 scale, grows to 1.035 over 0.26 seconds, and settles to 1 over 0.08 seconds before the next item appears.
- Progress begins only after all three reveal animations complete.
- The 128×128 reusable vector `TasuHub` mark sits around 42% viewport height. The 340×18 fully rounded track sits around 76% viewport height, with the live status line directly below it. `TasuHub · v<version>` is right-aligned in the bottom-right corner.
- Progress fill uses a slow 0.85 second Quint size tween. Layout dimensions do not animate.
- Percentage uses two synchronized labels: light text on the dark track and dark text clipped by the light fill.
- Status updates set new text and fade to the shared muted transparency over 0.42 seconds without moving or resizing content.
- Completion holds for 0.95 seconds. Icon, bar, and status then slide beyond the actual top viewport edge with 0.8 second Quint-In acceleration, starting 0.6 seconds apart. The background waits 1.5 seconds after the status slide starts, then exits with the same 0.8 second fade used at entry.
- Audio registry: fade-in/out use Roblox asset `1127797047` with different playback speeds, pop-in uses `140323850218372`, and pop-out uses `137081214744553`. Every reveal and every exit slide triggers its corresponding sound. Audio failure is non-blocking.
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

Run the canonical executor entrypoint on a fresh client and on a second execution. Confirm the background finishes fading before any content appears; icon, bar, and status pop in sequentially with a small overshoot and matching pop sounds; progress remains at zero until those reveals finish; the progress is monotonic; and percentage inversion stays synchronized. On completion, confirm icon, bar, and status cross the actual top viewport edge at exact 0.6 second start intervals with visible acceleration and matching exit sounds. Confirm the background waits 1.5 seconds after the third slide starts, plays the fade-out sound, exits in the same 0.8 seconds used at entry, leaves no overlay, reveals no legacy UI, and creates no duplicate loader after reload. Audio permission failures may silence a cue but may not delay or break the sequence. Review the executor console for property/tween errors.
