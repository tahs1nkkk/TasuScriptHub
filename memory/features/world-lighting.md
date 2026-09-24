# Feature memory: lighting modes

State: `LightingMode`, `GlowIntensity`, `NeonIntensity`, `NeonSize`, `NeonThreshold`, manual RGB/brightness/contrast/saturation values.

Behavior: applies default, glow, neon glow, or manual post-processing/lighting changes.

Rework: one world-visual controller owns effects, captures originals once, updates existing instances, and restores without touching the application theme.

Executor checks: every mode, parameter limits, game lighting changes, camera replacement, mode switching, disable/default, and unload.

