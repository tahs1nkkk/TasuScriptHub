# Feature memory: Aim targeting

State: `TargetPart`, `TeamCheck`, `WallCheck`, `MaxDistance`; `AliveCheck` is currently dead state.

Behavior: ranks on-screen living candidates within FOV and optionally rejects teammates or obstructed targets.

Rework: define deterministic eligibility and scoring, handle R6/R15 missing parts, and either implement or remove `AliveCheck`.

Executor checks: team/no-team games, dead characters, missing target part, walls, off-screen targets, distance boundary, join/leave, and respawn.

