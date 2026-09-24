# System memory: full-screen loader

Status: first reworked UI system implemented.

## Approved behavior

- A `Base` dark-gray full-screen scrim at 0.20 transparency covers the complete viewport and ignores the Roblox inset through the parent `ScreenGui`; the game view remains visible through a tracked `BlurEffect` whose size animates from 0 to 34.
- The background, blur, and bottom grid enter over 0.5 seconds. Exit does not fade: the complete loader moves downward over 2 seconds with Quint-In acceleration while blur animates back to zero.
- Only after the background entry completes, icon, progress bar, and status text reveal sequentially. Each fades in while starting at 0.82 scale, grows to 1.035 over 0.26 seconds, and settles to 1 over 0.08 seconds before the next item appears.
- Progress begins only after all three reveal animations complete.
- The 240×240 reusable vector `TasuHub` mark sits around 42% viewport height. The 480×28 fully rounded track sits around 80% viewport height, with an 18 px live status line directly below it. `TasuHub · v<version>` uses 13 px text and is right-aligned in the bottom-right corner.
- Progress fill uses a slow 1.4 second Quint size tween. Layout dimensions do not animate during ordinary progress updates.
- The rounded track/frame is white and the moving fill is `Layer` gray. Percentage uses two synchronized labels: gray text on the white track and white text clipped by the gray fill.
- Status updates are attached to completed runtime construction boundaries rather than a fake timer. Each update is applied immediately and yields one scheduler frame, so even millisecond-scale Core/UI/feature headings can render while the script continues loading.
- At 100%, the fill first completes its 1.4 second tween. The progress bar then scales toward its center from 1 to 0.02 and disappears over 0.7 seconds. Status changes to `Herşey Hazır!`, shifts upward from 80% to 76% viewport height, scales to 1.18, and turns `Success` (`#4FE08D`) over 1.2 seconds. The completed state remains for 1.8 seconds before exit.
- The former top-edge glow is removed. `BottomDotGrid` begins at 40% viewport height and fills the lower 60% with 60×22 responsive vector dots. Row progress is squared so size grows from 2 to 11 px and transparency changes from 0.98 to 0.62 toward the bottom, matching the supplied halftone reference without a raster asset.
- Loader-specific icon, bar, status, and background shadows are completely removed.
- No content item has an independent exit tween. The full loader background, dot grid, and all descendants move together to the bottom of the viewport. The loader is hidden only after the background fully clears the screen.
- Audio registry: entry/exit use Roblox asset `1127797047`; pop-in and the bar-collapse pop-out variants use `140323850218372` with different playback speeds. Each reveal, completion collapse, and complete-loader exit trigger their corresponding sound. Audio failure is non-blocking.
- Normal loader visuals use only `Base`, `Layer`, and `Signal`; the final confirmed state alone may use the shared `Success` token from `THEME_RULES.md`.

## Shared icon contract

`UI.IconLibrary.TasuHub` constructs the mark from scalable Roblox frames. `UI.CreateIcon(parent, "TasuHub", options)` accepts `Size`, `Color`, and `ZIndex`, so the same geometry can be reused at different sizes without remote assets.

## Runtime status checkpoints

- 6% — `Core · tema, ikon ve loader hazır`
- 18% — `UI · pencere ve durum bileşenleri hazır`
- 25% — `Categories · 9 kategori sayfası hazır`
- 30% — `Search · indeks ve sonuç görünümü bağlanıyor`
- 38% — `Search · indeksleme ve gezinme sistemi hazır`
- 46% — `Aim · hedefleme ve tahmin motoru hazır`
- 54% — `Visuals · ESP ve çizim motoru hazır`
- 60% — `Runtime · hareket ve dünya motorları hazır`
- 64% — `Categories · özellik panelleri oluşturuluyor`
- 72% — `Visuals · önizleme ve kontrol seçenekleri hazır`
- 78% — `Movement · hareket ve koruma özellikleri hazır`
- 83% — `World · ışık, kamera ve waypoint sistemi hazır`
- 87% — `Players · canlı oyuncu listeleme sistemi hazır`
- 90% — `Catalog · script yükleme sistemi hazır`
- 92% — `Configs · kayıt ve geri yükleme sistemi bağlanıyor`
- 97% — `Configs · dosya listesi ve modal hazır`
- 99% — `Runtime · executor API ve cleanup hazır`
- 100% — `Herşey Hazır!`

## Executor acceptance

Run the canonical executor entrypoint on a fresh client and on a second execution. Confirm the game scene is visibly blurred behind the 20%-transparent dark scrim; no top fade or shadow object remains; and the denser responsive dot grid begins around 40% viewport height, grows toward the bottom, and never enters the upper 40%. Confirm the gray-on-white/white-on-gray percentage inversion stays synchronized and that real construction headings visibly advance through Core, UI, Search, Aim, Visuals, Movement, World, Players, Catalog, Configs, and Runtime without a fake timer. Confirm the bar collapses into its center at 100%, and the enlarged green `Herşey Hazır!` moves slightly upward and remains for 1.8 seconds. During the 2 second exit, confirm the complete loader moves together and the blur returns smoothly to zero. Confirm no blur, overlay, legacy UI, or duplicate loader remains after exit/reload. Audio permission failures may silence a cue but may not delay or break the sequence. Review the executor console for property/tween errors.
