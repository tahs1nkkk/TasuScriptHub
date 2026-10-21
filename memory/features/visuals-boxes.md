# Feature memory: ESP boxes

State: `Boxes`, `BoxFilled`, `Thickness`.

Behavior: the current branch uses one AlwaysOnTop `BoxHandleAdornment` fill plus twelve AlwaysOnTop thin `BoxHandleAdornment` edges around a transparent welded body-bounds proxy. Bounds use body `BasePart` descendants only; Accessory and Tool descendants never change width. Screen-space rectangle boxes and `SelectionBox` are prohibited.

Rework: XRay-style AlwaysOnTop adornments remain visible through walls, fill uses 0.58 transparency, and thickness maps to bounded edge geometry. A game-overlay claim hides the complete general record for that target. Cleanup destroys only owned proxies/adornments; screen projection remains only for the box-attached health bar.

Executor checks: R6/R15, scaled avatars, accessories, seated/dead players, fill on/off, thickness limits, respawn, and unload.

Main UI revision 2: box/fill/thickness controls are descriptor-backed `Visuals` rows; renderer ownership is unchanged. Verify search targeting, card expansion, and page replacement.
