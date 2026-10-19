# Feature memory: flat textures

State: `FlatTextures`.

Behavior: removes texture/material maps client-side while preserving object colors and restores cached properties.

Rework: track descendants incrementally, retain a strong owned snapshot until disable/unload, skip unsupported instances safely, restore only properties actually changed, then clear the snapshot. A weak-key table is forbidden here because it can lose changed instances before restoration.

Executor checks: existing/new descendants, meshes, decals/textures, terrain exclusions, large maps, toggle cycles, and unload.

Main UI revision 2: the stable flag is displayed under `Lighting`; the page owns no descendant cache. Category/search transitions must not rescan the world.
