# Feature memory: flat textures

State: `FlatTextures`.

Behavior: removes texture/material maps client-side while preserving object colors and restores cached properties.

Rework: track descendants incrementally, use weak ownership, skip unsupported instances safely, and restore only properties actually changed.

Executor checks: existing/new descendants, meshes, decals/textures, terrain exclusions, large maps, toggle cycles, and unload.

Main UI revision 1: the toggle is exposed through `Dünya`; the page owns no descendant cache. Category/search transitions must not rescan the world.
