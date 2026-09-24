# Feature memory: anti-fling

State: `AntiFling`.

Behavior: tracks safe transform and humanoid settings, limits disruptive velocity/state, and restores original properties.

Rework: distinguish normal fast movement from hostile fling, keep recovery bounded, and never fight enabled flight/fling controllers without an explicit priority rule.

Executor checks: ordinary movement, vehicle/seated state, knockback, extreme velocity, flight interaction, respawn, disable, and unload.

