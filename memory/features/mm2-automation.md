# Feature memory: MM2 pickup and fire automation

State: MM2 `AutoPickup`, `AutoFire`, `AutoFarm`, `FarmSpeed`, `UndergroundOffset`; manual pickup/fire actions share the same service.

Behavior: pickup uses prompt/touch helpers. Shooting equips Gun, finds a `ShootGun` RemoteFunction, predicts murderer position, and invokes the MM2 shot contract without moving camera or mouse. Auto Fire additionally requires viewport and physical raycast visibility and has a 0.75-second cooldown.

Farm dynamically discovers collectible containers/models, sinks to the configured offset, travels at constant speed with noclip, fires remote touch without surfacing, and acknowledges removal/transparency/bag-count changes. It retries twice per item and stops after five consecutive failures. Bag-full handling shoots as Sheriff, uses Knife/touch as Murderer, and waits as Innocent; lobby/round polling continues while enabled.

Executor checks: helper present/missing, Gun absent/equipped/backpack, murderer absent/visible/occluded, invalid RemoteFunction, cooldown, seasonal bag HUD variants, multiple maps, no collectibles, touch acknowledgement/failure stop, role-specific round finish, death/respawn, manual stop, hub unload, and re-execution. Failed paths report failure and never claim success.
