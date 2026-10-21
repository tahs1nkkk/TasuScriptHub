# System memory: TasuHub action rail

Status: premium rail revision implemented; executor acceptance pending.

## Composition

- `CornerActionRail` is loader-owned under `InterfaceRoot`; it never reveals legacy presentation.
- Two base 70×70 buttons launch catalog and main menu. Each loaded game controller prepends one matching official-icon button. All share the existing rounded `Layer` surface, 6 px `Base` outline, hover/press geometry, audio, drag suppression, and clipping-safe padding.
- The visibility bar stays attached to the active viewport edge, shares the rail theme, remains silent, and rotates its arrow to communicate hide/show direction.

## Dock contract

- Valid regions are exactly `Left`, `Top`, and `Bottom`. The right edge is reserved for Bind HUD and can never be selected programmatically or by drag.
- Default is `Bottom` at dock ratio `0.08`, placing the rail near the lower-left area after loader exit.
- Left uses a vertical stack. Top and Bottom use a horizontal stack. Dynamic game buttons recalculate fixed centers and bounds without `UIListLayout`.
- Drag chooses the nearest allowed edge only. Moving the pointer to the right side therefore resolves to whichever of Left/Top/Bottom is nearest; it never produces a Right dock.
- Along-edge ratio is preserved across viewport changes. Hide offset and arrow orientation follow the active allowed edge.

## Lifecycle and acceptance

- Rail stays hidden through loader exit and reveals only afterward. Every input/resize connection belongs to global lifecycle; dynamic icon tasks verify ownership.
- Confirm default bottom-left position, horizontal top/bottom layout, vertical left layout, no Right state after aggressive right-side drag or `SetCornerDock("Right")`, fixed hover gaps, silent visibility bar, game-button insertion, resize, double execution, and unload cleanup.
