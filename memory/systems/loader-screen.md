# System memory: full-screen loader

Status: first reworked UI system implemented.

## Approved behavior

- A `Base` dark-gray full-screen scrim at 0.18 transparency covers the complete viewport and ignores the Roblox inset through the parent `ScreenGui`; the game view remains visible through a tracked `BlurEffect` whose size animates from 0 to 28.
- The background, blur, and bottom grid enter over 0.5 seconds. Exit does not fade: the complete loader moves downward over 2.4 seconds with Quint-In acceleration while blur animates back to zero.
- Only after the background entry completes, icon, progress bar, and status text reveal sequentially. Each fades in while starting at 0.82 scale, grows to 1.035 over 0.26 seconds, and settles to 1 over 0.08 seconds before the next item appears.
- Progress begins only after all three reveal animations complete.
- The 240×240 reusable vector `TasuHub` mark sits around 42% viewport height. The 480×28 fully rounded track sits around 80% viewport height, with an 18 px live status line directly below it. `TasuHub · v<version>` uses 13 px text and is right-aligned in the bottom-right corner.
- Progress fill uses a slow 0.85 second Quint size tween. Layout dimensions do not animate.
- Percentage uses two synchronized labels: light text on the dark track and dark text clipped by the light fill.
- Status updates set new text and fade to the shared muted transparency over 0.42 seconds without moving or resizing content.
- At 100%, status becomes `Herşey Hazır!`. Its text and the progress-bar `UIStroke` animate to `Success` (`#4FE08D`) over 1.2 seconds, with the stroke becoming clearly visible at 0.16 transparency. The completed state remains for a total of 2.5 seconds before exit.
- The former top-edge glow is removed. `BottomDotGrid` fills exactly the lower half of the viewport with 48×18 responsive vector dots. Row progress is squared so size grows from 2 to 11 px and transparency changes from 0.98 to 0.62 toward the bottom, matching the supplied halftone reference without a raster asset.
- Icon depth uses four enlarged copies of the exact vector mark, offset right/down by 8–23 px. The progress bar uses three sliced soft-shadow layers offset by 8–22 px. Status text uses three synchronized text shadows offset by 4–13 px. All shadows use `Base` and reveal with their owning content.
- No content item has an independent exit tween. The full loader background, dot grid, shadows, and all descendants move together to the bottom of the viewport. The loader is hidden only after the background fully clears the screen.
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

Run the canonical executor entrypoint on a fresh client and on a second execution. Confirm the game scene is visibly blurred behind the translucent dark scrim; no top fade remains; and the responsive dot grid begins at screen center, grows toward the bottom, and never crosses into the upper half. Confirm the icon, bar, and status shadows follow their exact shapes, point right/down, feel soft rather than duplicated, and remain readable over varied game scenes. Confirm progress remains at zero until content reveals finish, percentage inversion stays synchronized, `Herşey Hazır!` and the bar border transition to green, and the completed state remains for 2.5 seconds. During the 2.4 second exit, confirm the complete loader moves together and the blur returns smoothly to zero. Confirm no blur, overlay, legacy UI, or duplicate loader remains after exit/reload. Audio permission failures may silence a cue but may not delay or break the sequence. Review the executor console for property/tween errors.
