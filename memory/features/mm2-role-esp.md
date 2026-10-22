# Feature memory: MM2 role ESP

State: MM2 `Enabled`, `MurdererESP`, `SheriffESP`, `InnocentESP`, `AvatarCardESP`, `WeaponCardESP`.

Behavior: resolves replicated role first and held Gun/Knife second. Murderer red, Sheriff blue, and Innocent green chams use centralized `DataColors`, constant translucent fill, and a slow pulsing AlwaysOnTop outline. Role color changes tween. Active targets claim the loader overlay registry, suppressing general ESP until release.

Avatar and weapon cards are independent, default-off stud-scaled Billboard overlays for Murderer/Sheriff only. One card centers; two are symmetric. Their outer Billboard is 40% smaller than revision 2 while two-pixel inner padding keeps avatar/weapon content dominant inside the reduced card. Avatar uses the Roblox headshot thumbnail. Weapon uses a sanitized visual Tool clone, rotates its model 90° right for a readable side profile, and preserves the current skin. If a player Tool is unavailable, the renderer searches replicated storage once per role for `DefaultGun`/`Gun` or `DefaultKnife`/`Knife` visual geometry and caches that default source.

Executor checks: verify each independent role toggle/default, slow outline pulse without fill flashing, wall visibility, tweened role changes, general ESP suppression/recovery, 40%-smaller card centering/symmetry/distance scale, large inner artwork, 90° side-profile skin orientation, replicated default weapon fallback, join/leave, respawn, round transition, disable, unload, and re-execution.
