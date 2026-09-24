# System memory: full-screen loader

Status: first reworked UI system implemented.

## Approved behavior

- A `Base` dark-gray full-screen scrim at 0.18 transparency covers the complete viewport and ignores the Roblox inset through the parent `ScreenGui`; the game view remains visible through a tracked `BlurEffect` whose size animates from 0 to 34.
- The background, blur, and bottom grid enter over 0.5 seconds. Exit does not fade: the complete loader moves downward over 2 seconds with Quint-In acceleration while blur animates back to zero.
- Only after the background entry completes, icon, progress bar, and status text reveal sequentially. Each fades in while starting at 0.82 scale, grows to 1.035 over 0.26 seconds, and settles to 1 over 0.08 seconds before the next item appears.
- Progress begins only after all three reveal animations complete.
- The 240×240 reusable vector `TasuHub` mark sits around 42% viewport height. The 480×28 fully rounded track sits around 80% viewport height, with an 18 px live status line directly below it. `TasuHub · v<version>` uses 13 px text and is right-aligned in the bottom-right corner.
- Progress fill uses a slow 1.4 second Quint size tween. Layout dimensions do not animate during ordinary progress updates.
- The rounded track/frame is white and the moving fill is black. Percentage uses two synchronized labels: black text on the white track and white text clipped by the black fill.
- Status updates set new text and fade to the shared muted transparency over 0.42 seconds without moving or resizing content.
- At 100%, the fill first completes its 1.4 second tween. The progress bar then scales toward its center from 1 to 0.02 and disappears over 0.7 seconds. Status changes to `Herşey Hazır!`, shifts upward from 80% to 76% viewport height, scales to 1.18, and turns `Success` (`#4FE08D`) over 1.2 seconds. The completed state remains for 2.5 seconds before exit.
- The former top-edge glow is removed. `BottomDotGrid` begins at 40% viewport height and fills the lower 60% with 60×22 responsive vector dots. Row progress is squared so size grows from 2 to 11 px and transparency changes from 0.98 to 0.62 toward the bottom, matching the supplied halftone reference without a raster asset.
- Each element uses exactly one black, right/down-shifted soft shadow: one enlarged copy of the exact icon vector, one sliced image behind the bar, and one same-text copy with a soft stroke behind status. The former multi-layer shadow arrays are removed.
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

Run the canonical executor entrypoint on a fresh client and on a second execution. Confirm the game scene is visibly blurred behind the translucent dark scrim; no top fade remains; and the denser responsive dot grid begins around 40% viewport height, grows toward the bottom, and never enters the upper 40%. Confirm icon, bar, and status each have exactly one black shadow copy shifted right/down, with no layered/duplicated look. Confirm progress remains at zero until content reveals finish, the black-on-white/white-on-black percentage inversion stays synchronized, the bar collapses into its center at 100%, and the enlarged green `Herşey Hazır!` moves slightly upward and remains for 2.5 seconds. During the 2 second exit, confirm the complete loader moves together and the blur returns smoothly to zero. Confirm no blur, overlay, legacy UI, or duplicate loader remains after exit/reload. Audio permission failures may silence a cue but may not delay or break the sequence. Review the executor console for property/tween errors.
