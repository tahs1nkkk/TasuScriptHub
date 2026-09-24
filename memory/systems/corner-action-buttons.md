# System memory: post-loader corner action buttons

Status: second reworked UI system implemented; executor verification pending.

## Approved composition

- `CornerActionRail` belongs directly to the new `InterfaceRoot`; it never enters `LegacyUIRoot` and does not reveal any old window, navigation, search, toast, modal, or feature panel.
- The rail is a four-edge dock, initially attached near the bottom of the right edge. Its dedicated `ButtonStack` contains two 70×70 `ImageButton` controls at fixed absolute center positions with an 18 px normal-state gap. There is no `UIListLayout` or automatic spacing path.
- Both buttons share the exact same appearance: 16 px rounded corners, a `Layer` background at 0.18 transparency, and a 6 px `Base` outline.
- Each button uses a centered 48×48 `ImageLabel` with a 0.5/0.5 anchor, 0.5/0.5 position, and `Fit` scaling. The upper slot uses Roblox decal `137753054375497` and is reserved for the games catalog. The lower slot uses decal `83533116222028` and is reserved for the general menu. The identical slots remain geometrically symmetric; a failed custom-asset conversion retains the direct Roblox asset source without changing layout.
- The rail, stack, and buttons use `ClipsDescendants = false`. The stack reserves 76×76 hover geometry plus 8 px on every side for the 6 px outline and two additional safety pixels. No transparent/invisible parent frame may crop or constrain the visible hover expansion.

## Motion and audio

- The rail remains hidden throughout loader construction, success hold, and downward exit. Only after loader destruction does the complete rail fade from full transparency over 0.34 seconds; button geometry is not changed during reveal.
- Pointer entry plays the short Roblox `RBLX UI Hover 02` tick (`10066936758`) at volume 0.045 and tweens that button from 70×70 to 76×76 while its icon grows from 48×48 to 52×52 over 0.22 seconds. Pointer leave restores both normal sizes.
- Mouse/touch press briefly uses a 67×67 button and 46×46 icon; release returns both to the current hover/rest targets. Center anchors, fixed center coordinates, clipping-free containers, and padded bounds make the whole button composition expand symmetrically without automatic repositioning.
- `UI Click 1` (`113397864512278`), formerly used on hover, now plays only on a valid button activation. Drag-suppressed activations do not play it. The temporary unload callback waits 0.12 seconds after the click cue begins so cleanup does not immediately cut it off.
- A borderless `Signal` visibility line stays flush to the selected viewport edge. It is 6×64 on left/right and 64×6 on top/bottom, has no hover or activation sound, and only changes transparency for hover feedback.
- Hiding moves `ButtonStack` and its group transparency beyond the selected edge over 0.44 seconds: negative X for left, positive X for right, negative Y for top, and positive Y for bottom. Showing reverses that exact path while the line remains visible.

## Edge docking and dragging

- A pointer drag beginning on either action button or on the visibility line becomes a dock drag after 6 px of movement. A completed drag suppresses click/toggle activation for 0.25 seconds.
- During drag, the pointer's nearest viewport edge selects `Left`, `Right`, `Top`, or `Bottom`. The rail immediately adopts that edge and follows only its legal along-edge axis; it cannot stay in the center.
- A normalized dock ratio preserves the along-edge position across viewport-size changes. An 8 px travel margin keeps the padded hover bounds and 6 px stroke inside the screen at both edge endpoints.
- Left/right docks use a vertical button stack with the silent line flush to the screen. Top/bottom docks retain the same fixed vertical stack but place it inward from a horizontal line. The hide direction always matches the active edge.

## Icon and action registry

- `SetCornerButtonIcon(index, assetId)` accepts slot 1 or 2, assigns `rbxassetid://<id>` immediately, then resolves the numeric Roblox asset through `UI.LoadRobloxThumbnailAsset`, caches it under `TasuHub/Icons/CornerButton<index>.png`, and replaces the source only when its revision still owns the slot. This dual executor path prevents a failed custom-asset conversion from clearing an otherwise usable Roblox source.
- `SetCornerButtonAction(index, callback)` owns the single optional callback for each slot. `Activated` runs the callback asynchronously so a feature action cannot block button input animation.
- Slot 1's intended action is `Catalog`, but during this intermediate build its `CurrentAction` is explicitly `Unload`; pressing it invokes the canonical idempotent TasuHub cleanup path. Replace only this callback when the catalog view is designed. Slot 2's intended action is `GeneralMenu`; it deliberately has no callback until the next UI step.
- `SetCornerButtonsHidden(hidden, instant)` is the single visibility path for the button stack. A revision guard prevents an older hide completion from disabling a newer show request.
- `SetCornerDock(side, ratio)` is the programmatic dock path. `env.TasuHub` exports it with the icon/action/visibility setters, the two button records, and their semantic definitions for executor diagnostics. Feature code must use these setters rather than constructing or restyling a parallel corner button.

## Lifecycle and executor acceptance

- Every button, visibility-line, global input, and viewport-resize connection is tracked by the global lifecycle owner. The rail and its descendants are destroyed with the tracked main `ScreenGui`; late asset workers verify both revision and instance ownership.
- Execute only through the canonical executor entrypoint. Confirm neither button appears before loader exit. After loader destruction, confirm exactly two equal 70×70 buttons appear on the right dock, retain the fixed 18 px normal gap, and never reveal legacy UI.
- Confirm each pointer entry emits only the short tick, activation emits the former click cue, and the visibility line remains silent. Only the hovered composition may grow to 76×76/52×52; no invisible frame or 6 px outline is clipped, pointer leave returns to 70×70/48×48, and pressing uses 67×67/46×46.
- Confirm both assigned decals appear and remain visually symmetric. Confirm the upper button fully unloads TasuHub once, while the lower button remains inert.
- Drag from buttons and the line toward all four edges. The rail must choose the nearest edge, never remain in the center or leave the viewport, preserve the along-edge position after resize, and suppress accidental unload/toggle after dragging.
- Hide/show repeatedly on every edge and during active transitions. The stack must clear the matching edge, the silent line must remain flush and clickable, and stale completions must not leave the returned stack invisible. Double-execute and unload during icon resolution; no duplicate rail, stale icon, sound, line, drag connection, or resize connection may survive.
