# Script memory: config_service.lua

Role: version-2 validated executor-file config controller.

It owns payload construction, schema/scalar/bind validation, JSON file list/save/load/delete, ordered apply stages, and partial-success reporting. Loader adapters provide control/game/bind/Auto-run/waypoint state and all executor filesystem functions. The module never accesses feature state, UI instances, or executor globals directly. See `../systems/config-storage.md`.
