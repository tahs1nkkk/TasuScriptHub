# System memory: full-screen loader

Status: first reworked UI system implemented.

## Approved behavior

- A `Base` dark-gray full-screen `Frame` covers the complete viewport and ignores the Roblox inset through the parent `ScreenGui`; the fixed center content uses its own `CanvasGroup`.
- The empty `Base` background fades in over 0.5 seconds. Exit does not fade: the complete loader moves downward over 2.4 seconds with Quint-In acceleration, compensating for the longer glow travel distance.
- Only after the background entry completes, icon, progress bar, and status text reveal sequentially. Each fades in while starting at 0.82 scale, grows to 1.035 over 0.26 seconds, and settles to 1 over 0.08 seconds before the next item appears.
- Progress begins only after all three reveal animations complete.
- The 240×240 reusable vector `TasuHub` mark sits around 42% viewport height. The 480×28 fully rounded track sits around 80% viewport height, with an 18 px live status line directly below it. `TasuHub · v<version>` uses 13 px text and is right-aligned in the bottom-right corner.
- Progress fill uses a slow 0.85 second Quint size tween. Layout dimensions do not animate.
- Percentage uses two synchronized labels: light text on the dark track and dark text clipped by the light fill.
- Status updates set new text and fade to the shared muted transparency over 0.42 seconds without moving or resizing content.
- At 100%, status becomes `Herşey Hazır!`. Its text and the progress-bar `UIStroke` animate to `Success` (`#4FE08D`) over 1.2 seconds, with the stroke becoming clearly visible at 0.16 transparency. The completed state remains for a total of 2.5 seconds before exit.
- No content item has an independent exit tween. The full loader background and all descendants move together to `viewport height + 1000 px`; a 1000 px upward-facing glow is anchored only to the background's top edge. The glow reads the exact loader background color and uses transparency keypoints `1.00 → 0.94 → 0.58 → 0.00`, creating the broad soft band shown in the reference. The loader is hidden only after the complete glow leaves the viewport.
- Audio registry: entry/exit use Roblox asset `1127797047` with different playback speeds and pop-in uses `140323850218372`. Each reveal and the single complete-loader exit trigger their corresponding sound. Audio failure is non-blocking.
- Normal loader visuals use only `Base`, `Layer`, and `Signal`; the final confirmed state alone may use the shared `Success` token from `THEME_RULES.md`.

## Shared icon contract

`UI.IconLibrary.TasuHub` constructs the mark from scalable Roblox frames. `UI.CreateIcon(parent, "TasuHub", options)` accepts `Size`, `Color`, and `ZIndex`, so the same geometry can be reused at different sizes without remote assets.

## Milestones

- 6% — `Arayüz hazırlanıyor`
- 22% — `Arayüz bileşenleri yükleniyor`
- 44% — `Özellikler hazırlanıyor`
- 70% — `Kategoriler oluşturuluyor`
- 90% — `Son kontroller yapılıyor`
- 100% — `Herşey Hazır!`

## Executor acceptance

Run the canonical executor entrypoint on a fresh client and on a second execution. Confirm the 0.5 second background entry finishes before any content appears; the 240 px icon, 480×28 bar, and 18 px status pop in sequentially with matching sounds; progress remains at zero until those reveals finish; progress is monotonic; and percentage inversion stays synchronized. At completion, confirm `Herşey Hazır!` and the bar border transition smoothly to green, the completed state remains for 2.5 seconds total, no content moves relative to the background, and the whole loader accelerates downward over 2.4 seconds. Confirm the shaped 1000 px glow matches the background exactly, exists only above the top edge, and fully clears the bottom before destruction. Confirm no overlay remains, no legacy UI appears, and no duplicate loader is created after reload. Audio permission failures may silence a cue but may not delay or break the sequence. Review the executor console for property/tween errors.
