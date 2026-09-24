# System memory: full-screen loader

Status: first reworked UI system implemented.

## Approved behavior

- A `Base` dark-gray full-screen scrim at 0.20 transparency covers the complete viewport and ignores the Roblox inset through the parent `ScreenGui`; the game view remains visible through a tracked `BlurEffect` whose size animates from 0 to 34.
- The background, blur, and bottom grid enter over 0.5 seconds. During exit the complete loader moves downward over `1.7/3` seconds (approximately 0.567 seconds) with Quint-In acceleration, its full `CanvasGroup` tree fades uniformly over the same duration, and blur animates back to zero.
- Only after the background entry completes, icon, progress bar, and status text reveal sequentially. Each fades in while starting at 0.82 scale, grows to 1.035 over 0.26 seconds, and settles to 1 over 0.08 seconds before the next item appears.
- Progress begins only after all three reveal animations complete.
- The 280×280 reusable `TasuHub` mark sits around 42% viewport height. Decal `138667112902223` renders at original multicolor through a runtime thumbnail-API → PNG download → `getcustomasset` pipeline; the authorization-blocked `rbxassetid` and executor-incompatible direct `rbxthumb` display paths are not used. All vector fallback geometry is removed, so failure leaves the reserved icon canvas empty. Once its reveal settles, the icon stays position-locked on its center anchor, breathes from scale 1 to 1.08, and rocks from −6° to +6° on a smooth 6.4 second sine loop. The 480×28 fully rounded track sits around 80% viewport height, with an 18 px live status line directly below it. `TasuHub · v<version>` uses 13 px text and is right-aligned in the bottom-right corner.
- Progress fill uses a slow 1.4 second Quint size tween. Layout dimensions do not animate during ordinary progress updates.
- The rounded track/frame is white and the moving fill is `Layer` gray. Percentage uses two synchronized `Signal`-white labels; the second remains clipped by the gray fill so both layers stay aligned through progress.
- Status updates are attached to completed runtime construction boundaries rather than a fake timer. Each update is applied immediately and yields one scheduler frame, so even millisecond-scale Core/UI/feature headings can render while the script continues loading.
- At 100%, the fill first completes its 1.4 second tween. The progress bar then scales silently toward its center from 1 to 0.02 and disappears over 0.7 seconds. Only when status changes to `Herşey Hazır!` does the final completion pop play; the text shifts upward from 80% to 76% viewport height, scales to 1.40, and turns `Success` (`#4FE08D`) over 1.2 seconds. The completed state remains for 1.8 seconds before exit.
- The former top-edge glow is removed. `BottomDotGrid` begins at 40% viewport height and fills the lower 60% with 60×22 responsive vector dots. The exact baseline is retained in `UI.LoaderDotRecords`: column/row positions, 2–11 px rounded sizes, and 0.98–0.62 transparency. Twenty-two animated row groups move upward at constant speed, completing one wrap every 5.2 seconds; row size and transparency continuously recompute from the original squared vertical curve. An 8% endpoint envelope multiplies that opacity down to zero at both the top and bottom before modulo wrapping, eliminating the one-frame full-opacity flash while preserving the supplied halftone appearance.
- Loader-specific icon, bar, status, and background shadows are completely removed.
- No content item has an independent exit tween. The full loader background, animated dot grid, icon, and all descendants move together to the bottom while the root `CanvasGroup.GroupTransparency` linearly reaches 1. The loader is hidden only after the background fully clears the screen.
- Audio registry: entry uses Roblox asset `1127797047`; exit uses soft, modern UI-whoosh asset `90657541635248` at volume 0.09. Playback speed `2/3` extends its native two-second recording to three seconds; `PitchShiftSoundEffect.Octave = 1.5` compensates pitch so stretching does not turn it dark or horror-like. The cue begins simultaneously with the approximately 0.567-second downward movement and finishes as a soft tail after the screen clears. Content pop-in and the final ready-text cue use `140323850218372`. The reverse horror-like whoosh, bar-collapse sound, and `PopOut` preset are removed. Audio failure is non-blocking.
- Normal loader visuals use only `Base`, `Layer`, and `Signal`; the final confirmed state alone may use the shared `Success` token from `THEME_RULES.md`.

## Shared icon contract

`UI.IconLibrary.TasuHub` reads decal ID and cache path from shared registry entry `UI.IconAssets.TasuHub`. An asynchronous worker queries `thumbnails.roblox.com`, downloads the current 420×420 PNG, saves `TasuHub/Icons/TasuHub.png`, resolves it with `getcustomasset`/`getsynasset`, and assigns it to the otherwise-empty `ImageLabel`. The worker checks instance ownership before applying a late response. `UI.CreateIcon(parent, "TasuHub", options)` accepts `Size` and `ZIndex`; the approved multicolor PNG preserves its original artwork and no vector/text fallback is constructed.

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

Run the canonical executor entrypoint on a fresh client and on a second execution. Confirm the game scene is visibly blurred behind the 20%-transparent dark scrim; no top fade or shadow object remains; and the denser responsive dot grid begins around 40% viewport height. Verify every row travels upward at the same constant speed, reaches zero opacity at both travel endpoints without a wrap flash, and preserves all 60 columns. On a full-capability executor, confirm decal `138667112902223` appears as the sole icon source, then breathes and rocks around its fixed center anchor without translating. If HTTP, file, thumbnail, or custom-asset loading is blocked, confirm the icon canvas remains empty rather than showing a fallback. Confirm the percentage remains white over both track states and real construction headings visibly advance without a fake timer. At 100%, confirm bar collapse is silent, the only completion pop occurs on the larger green `Herşey Hazır!`, and the ready state remains for 1.8 seconds. Confirm the louder pitch-compensated soft UI whoosh starts simultaneously with the downward movement, lasts three seconds, and has no horror/reverse character. During the approximately 0.567-second exit, confirm every visual fades at one linear rate while the complete loader accelerates downward and dot/icon loops stop only after the loader clears the screen. Confirm no animation connection, blur, overlay, legacy UI, or duplicate loader remains after exit/reload. Audio permission failures may silence a cue but may not delay or break the sequence. Review the executor console for property/tween errors.
