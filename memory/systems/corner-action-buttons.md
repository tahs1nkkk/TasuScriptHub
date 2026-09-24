# System memory: post-loader corner action buttons

Status: second reworked UI system implemented; executor verification pending.

## Approved composition

- `CornerActionRail` belongs directly to the new `InterfaceRoot`; it never enters `LegacyUIRoot` and does not reveal any old window, navigation, search, toast, modal, or feature panel.
- The rail is anchored to the bottom-right viewport corner with 24 px safe margins. Its dedicated `ButtonStack` contains two 78×78 `ImageButton` controls at fixed absolute center positions with an 18 px normal-state gap. There is no `UIListLayout` or automatic spacing path.
- Both buttons now deliberately share the exact same appearance: 16 px rounded corners, a `Layer` background at 0.18 transparency, and a 3 px `Base` outline.
- Each button uses a centered 38×38 `ImageLabel` with a 0.5/0.5 anchor, 0.5/0.5 position, and `Fit` scaling. The upper slot uses Roblox decal `137753054375497` and is reserved for the games catalog. The lower slot uses decal `83533116222028` and is reserved for the general menu. The identical slots remain geometrically symmetric; a failed custom-asset conversion retains the direct Roblox asset source without changing layout.
- The rail and stack both use `ClipsDescendants = false`, and rail geometry reserves the complete 84×84 hover bounds. No transparent/invisible parent frame may crop or constrain the visible hover expansion.

## Motion and audio

- The rail remains hidden throughout loader construction, success hold, and downward exit. Only after loader destruction does the complete rail fade from full transparency over 0.34 seconds; button geometry is not changed during reveal.
- Pointer entry plays shared Roblox asset `113397864512278` at volume 0.08 once and tweens only that button's real `Size` from 78×78 to 84×84 over 0.22 seconds with Quint-Out. Pointer leave restores 78×78.
- Mouse/touch press briefly uses 74×74 and release returns to the current 84×84 hover or 78×78 rest target. Both buttons use center anchors, fixed center coordinates, clipping-free containers, and reserved maximum bounds, so direct size animation expands symmetrically without automatic repositioning.
- A 30×44 arrow control is fixed 10 px to the right of the 84 px maximum button bounds. On activation, only `ButtonStack` moves horizontally beyond the right edge and fades to full transparency over 0.44 seconds; the arrow stays visible and rotates 180°. A second activation makes the stack visible first, then slides/fades it back to its exact fixed coordinates.

## Icon and action registry

- `SetCornerButtonIcon(index, assetId)` accepts slot 1 or 2, assigns `rbxassetid://<id>` immediately, then resolves the numeric Roblox asset through `UI.LoadRobloxThumbnailAsset`, caches it under `TasuHub/Icons/CornerButton<index>.png`, and replaces the source only when its revision still owns the slot. This dual executor path prevents a failed custom-asset conversion from clearing an otherwise usable Roblox source.
- `SetCornerButtonAction(index, callback)` owns the single optional callback for each slot. `Activated` runs the callback asynchronously so a feature action cannot block button input animation.
- Slot 1's intended action is `Catalog`, but during this intermediate build its `CurrentAction` is explicitly `Unload`; pressing it invokes the canonical idempotent TasuHub cleanup path. Replace only this callback when the catalog view is designed. Slot 2's intended action is `GeneralMenu`; it deliberately has no callback until the next UI step.
- `SetCornerButtonsHidden(hidden, instant)` is the single visibility path for the button stack. A revision guard prevents an older hide completion from disabling a newer show request.
- `env.TasuHub` exports all three setters, the two button records, and their semantic definitions for executor diagnostics. Feature code must use these setters rather than constructing or restyling a parallel corner button.

## Lifecycle and executor acceptance

- Every button and arrow connection is tracked by the global lifecycle owner. The rail and its descendants are destroyed with the tracked main `ScreenGui`; late asset workers verify both revision and instance ownership.
- Execute only through the canonical executor entrypoint. Confirm neither button appears before loader exit. After loader destruction, confirm exactly two equal 78×78 buttons appear 24 px from the bottom-right edge, remain at the fixed 18 px normal gap, and never reveal legacy UI.
- Confirm each pointer entry emits one short click, only the hovered button grows symmetrically to 84×84, no invisible frame clips it, pointer leave returns exactly to 78×78, pressing uses 74×74, and the second button never moves when the first changes size.
- Confirm both assigned decals appear, are centered, use equal 38×38 bounds, and remain visually symmetric during size animation. Test valid, invalid, permission-blocked, and rapidly replaced IDs. Confirm the upper button fully unloads TasuHub once, while the lower button remains inert.
- Toggle the arrow repeatedly during both hide and show animations. The two buttons must fade and clear the right edge, the arrow must remain clickable, and stale completions must not leave the returned stack invisible. Double-execute and unload during icon resolution; no duplicate rail, stale icon, sound, arrow, or connection may survive.
