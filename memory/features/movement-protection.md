# Feature memory: anti-fling

State: `AntiFling` (Static Anti Fling) and `AntiFlingMoving` (Moving Anti Fling). They are mutually exclusive.

Behavior: Static Anti Fling retains the anchored protection path. Moving Anti Fling keeps the avatar mobile, updates a safe transform during normal motion, and restores it while clearing linear/angular velocity when bounded hostile thresholds or `PlatformStand` are detected.

Rework: distinguish normal fast movement from hostile fling, keep recovery bounded, and never fight enabled flight/fling controllers without an explicit priority rule.

Executor checks: ordinary movement, vehicle/seated state, knockback, extreme velocity, flight interaction, respawn, disable, and unload.

Main UI revision 2: both anti-fling modes are descriptor-backed `Misc` toggles. Player-service targeted fling temporarily suspends and restores both modes; verify both cross-control refresh paths. Client-side mitigation cannot promise immunity from every server-authoritative or network-owned physics result.
