# Script memory: bind_service.lua

Role: version-1 central bind registry, input router, right-center HUD, assignment order, feedback state, and shared cooldown scheduler.

It is created by `loader.lua`, stays visually disabled until loader exit, receives only controller callbacks and central icon/color tokens, and owns no gameplay behavior. See `../systems/keybinds.md` for the exact contract and executor matrix.
