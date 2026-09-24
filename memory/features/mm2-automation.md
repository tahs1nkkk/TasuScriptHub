# Feature memory: MM2 pickup and fire automation

State: MM2 `AutoPickup`, `AutoFire`; manual pickup/fire actions share the same controllers.

Behavior: uses proximity/touch helpers for pickup and discovered gun remotes for firing at the resolved murderer.

Rework: capability-gated actions, cooldown/rate limits, target validation, structured failure reasons, and no claim of success when no supported path exists.

Executor checks: helper present/missing, gun absent, murderer absent, invalid remote, round transition, manual action, automatic loop, disable, and unload.

