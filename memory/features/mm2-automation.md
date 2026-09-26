# Feature memory: MM2 pickup and fire automation

State: MM2 `AutoPickup`, `AutoFire`; manual pickup/fire actions share the same controllers.

Behavior: uses proximity/touch helpers for pickup and discovered gun remotes for firing at the resolved murderer.

Rework status: preserved automatic state is exposed through shared-theme `Otomatik Alma` and `Otomatik Ateş` controls; `Silahı Şimdi Al` and `Şimdi Ateş Et` call the same engine actions. The footer reports structured success/failure without a private toast or separate feature window. Capability checks, target validation, and existing 0.15-second loop ownership remain in the engine.

Executor checks: helper present/missing, gun absent, murderer absent, invalid remote, round transition, both manual actions, both automatic controls, main-system disable, window close/reopen, hub unload, and re-execution. A failed path must show failure and must not claim success; unload must stop the loop and clear retained targets.
