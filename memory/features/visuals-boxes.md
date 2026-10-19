# Feature memory: ESP boxes

State: `Boxes`, `BoxFilled`, `Thickness`.

Behavior: the current branch uses four screen-space box lines plus a clipped fill computed from visible body-part bounds. The renderer stays visible through walls because it is application overlay geometry, not a world `SelectionBox`.

Rework: keep renderer interchangeable, avoid physical/collision impact, update bounds after avatar scale changes, exclude `Accessory` and `Tool` descendants from hitbox width, use 0.62 fill transparency when filled, and destroy only owned proxies on character swap.

Executor checks: R6/R15, scaled avatars, accessories, seated/dead players, fill on/off, thickness limits, respawn, and unload.

Main UI revision 2: box/fill/thickness controls are descriptor-backed `Visuals` rows; renderer ownership is unchanged. Verify search targeting, card expansion, and page replacement.
