# Feature memory: ESP boxes

State: `Boxes`, `BoxFilled`, `Thickness`.

Behavior: current verified build uses native 3D bounds through a proxy and selection box.

Rework: keep renderer interchangeable, avoid physical/collision impact, update bounds after avatar scale changes, and destroy proxies on character swap.

Executor checks: R6/R15, scaled avatars, accessories, seated/dead players, fill on/off, thickness limits, respawn, and unload.

