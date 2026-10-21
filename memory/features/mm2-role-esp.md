# Feature memory: MM2 role ESP

State: MM2 `Enabled`, `MurdererESP`, `SheriffESP`, `InnocentESP`, `AvatarCardESP`, `WeaponCardESP`.

Behavior: resolves replicated role first and held Gun/Knife second. Murderer red, Sheriff blue, and Innocent green chams use centralized `DataColors`, constant translucent fill, and a slow pulsing AlwaysOnTop outline. Role color changes tween. Active targets claim the loader overlay registry, suppressing general ESP until release.

Avatar and weapon cards are independent, default-off stud-scaled Billboard overlays for Murderer/Sheriff only. One card centers; two are symmetric. Avatar uses the Roblox headshot thumbnail; weapon uses a sanitized visual Tool clone in a ViewportFrame and preserves the current skin.

Executor checks: verify each independent role toggle/default, slow outline pulse without fill flashing, wall visibility, tweened role changes, general ESP suppression/recovery, card centering/symmetry/distance scale/skin, join/leave, respawn, round transition, disable, unload, and re-execution.
