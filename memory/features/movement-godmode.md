# Feature memory: godmode

Status: removed in the current improvement pass because the local implementation did not provide truthful working behavior.

Removed ownership: default state, runtime controller/reset callback override, UI descriptor, unload/reset logic, and service dependency. Old config payloads may contain `Movement.Godmode`; load migration clears that key and never exposes it.

Executor checks: old configs containing the key load without error, no Godmode row appears, Reset remains game-owned, repeated execution leaves no reset callback override, and unload has no Godmode cleanup branch.
