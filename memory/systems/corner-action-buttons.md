# System memory: post-loader corner action buttons

Status: second reworked UI system implemented; executor verification pending.

## Approved composition

- `CornerActionRail` belongs directly to the new `InterfaceRoot`; it never enters `LegacyUIRoot` and does not reveal any old window, navigation, search, toast, modal, or feature panel.
- The rail is anchored to the bottom-right viewport corner with 24 px safe margins. It is 60 px wide and contains two 60×60 `ImageButton` controls stacked vertically with a 12 px gap.
- Both buttons use 16 px rounded corners, 1.5 px border strokes, and 0.18 background transparency. The upper button is `Base` with a `Signal` outline; the lower is `Layer` with a `Base` outline.
- Each button reserves a centered 30×30 `ImageLabel`. No asset ID or semantic action is assumed in this step. Empty slots remain blank without fallback artwork and do not affect geometry.

## Motion and audio

- The rail remains hidden throughout loader construction, success hold, and downward exit. Only after loader destruction does it fade from full transparency over 0.34 seconds.
- Buttons reveal from 0.88 to 1 scale using Back-Out over 0.34 seconds, with the lower button beginning 0.08 seconds after the upper one.
- Pointer entry plays shared Roblox asset `113397864512278` at volume 0.08 once and scales the hovered button to 1.07 over 0.22 seconds with Quint-Out. Pointer leave restores scale 1 over the same duration.
- Mouse/touch press briefly scales to 0.96 and release returns to the current hover/rest target. Scale feedback uses `UIScale`, so stack dimensions and layout never reflow.

## Icon and action registry

- `SetCornerButtonIcon(index, assetId)` accepts slot 1 or 2, clears the prior image immediately, resolves the numeric Roblox asset through `UI.LoadRobloxThumbnailAsset`, caches it under `TasuHub/Icons/CornerButton<index>.png`, and applies it only when its revision still owns the slot.
- `SetCornerButtonAction(index, callback)` owns the single optional callback for each slot. `Activated` runs the callback asynchronously so a feature action cannot block button input animation.
- `env.TasuHub` exports both setters and the two button records for executor diagnostics. Feature code must use the setters rather than constructing or restyling a parallel corner button.

## Lifecycle and executor acceptance

- Every button connection is tracked by the global lifecycle owner. The rail and its descendants are destroyed with the tracked main `ScreenGui`; late asset workers verify both revision and instance ownership.
- Execute only through the canonical executor entrypoint. Confirm neither button appears before loader exit. After loader destruction, confirm exactly two buttons appear 24 px from the bottom-right edge, remain stacked at 12 px spacing, and never reveal legacy UI.
- Confirm each pointer entry emits one short click, only the hovered button grows, repeated enter/leave returns exactly to scale 1, pressing does not reflow the rail, and both borders remain visually distinct in the three-color theme.
- After icon IDs are supplied, test valid, invalid, permission-blocked, and rapidly replaced IDs. Confirm missing capability leaves the slot blank without runtime errors. Double-execute and unload during icon resolution; no duplicate rail, stale icon, sound, or connection may survive.
