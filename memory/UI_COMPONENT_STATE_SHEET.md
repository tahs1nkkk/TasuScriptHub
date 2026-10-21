# Premium UI component state sheet

All states use `THEME_RULES.md`; semantic data colors are allowed only through centralized `DataColors`.

| Component | Rest | Hover/focus | Active/selected | Disabled/error | Loading/cooldown |
| --- | --- | --- | --- | --- | --- |
| Button/action | `Layer`, subtle `Base` outline | lower transparency, shared hover tick | press shrink/settle, `Signal` | muted; `Danger` on rejection | optional clipped mask |
| Toggle | `Layer` track, `Signal` knob | surface emphasis | `Signal` track, `Base` knob | muted, no action | none |
| Slider | `Layer` track | focused value emphasis | `Signal` fill | muted | none |
| Dropdown/input | flat `Layer` surface | `Signal` outline | one owned popup/focus | `Danger` validation | none |
| Section | flat title + thin divider | disclosure emphasis | content visible | n/a | reveal opacity only |
| Search result | category/section/control hierarchy | surface emphasis | negative theme pulse | n/a | none |
| Status badge | semantic `DataColors`/status color | unchanged | unchanged | `Danger` | none |
| Player row | flat row | surface emphasis | action icon feedback | rejected action cue | action-owned cooldown only |
| Toast/modal | shared elevated surface | control-specific | semantic border/message | `Danger` | revision owned |
| Bind HUD icon | low-opacity metadata tint | n/a | full active tint + press | red reject pulse | gray top-to-bottom reveal mask |

Mockup geometry: main and catalog are 780×520 `Rail + Workspace`; game packages are at most 620×420. Main content uses flat sections and two columns, catalog uses a virtual 3×3 workspace, and MM2 uses the smaller `ESP/AIM/FARM` rail. Rail, workspaces, search, status, and package windows share the same component primitives and three-color theme.
