# Feature memory: ESP boxes

State: `Boxes`, `BoxFilled`, `Thickness`.

Behavior: the current branch uses one real world-space `SelectionBox` welded through a transparent, non-colliding proxy to each live character root. Bounds are calculated only from body `BasePart` descendants; `Accessory` and `Tool` descendants never change box width. Screen-space GUI rectangle boxes are prohibited and must not be reintroduced unless the user explicitly reverses this contract.

Rework: avoid physical/collision impact, rebuild the owned proxy after a character swap, use 0.58 surface transparency when filled, map shared thickness into a bounded 3D line thickness, and destroy only owned proxies on character swap/unload. Screen projection remains only for the box-attached health bar.

Executor checks: R6/R15, scaled avatars, accessories, seated/dead players, fill on/off, thickness limits, respawn, and unload.

Main UI revision 2: box/fill/thickness controls are descriptor-backed `Visuals` rows; renderer ownership is unchanged. Verify search targeting, card expansion, and page replacement.
