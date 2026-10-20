# Feature memory: Visuals core

State: `Visuals.Enabled`, `MaxDistance`, `Thickness`.

Behavior: owns per-player ESP records and render/update cleanup.

Rework: one record lifecycle per player/character, bounded update frequency for text, and explicit renderer ownership. Feature overlays are separate from application UI.

Executor checks: enable/disable, join/leave, respawn, distance boundary, camera replacement, repeated execution, and unload.

Main UI revision 2: core controls use stable `Visuals` descriptors. The page owns no player records or render loop; verify state refresh and unload during animation.

Improvement pass: unload sets `Visuals.Enabled = false` before renderer/controller destruction. Record cleanup enumerates only TasuHub-owned GUI/adornment keys and line arrays; it never destroys the live `WorldCharacter` reference. This fixes the prior client-side character disappearance on unload.

Current layering: the one application `ScreenGui` uses global Z-index ordering. ESP GUI primitives remain in the low 1–4 band, while the rail/catalog/main/game windows remain in their established 2000+ bands, so application windows always paint above cheat visuals. World-space adornments remain in the 3D scene and never construct a competing UI root.
