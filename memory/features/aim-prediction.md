# Feature memory: Aim prediction

State: `Prediction`, `PredictionTime`.

Behavior: offsets the chosen target using velocity and configured lead time.

Rework: clamp unstable velocity, reset target history on character change, and keep prediction independent from UI frame rate.

Executor checks: stationary, walking, jumping, sudden direction change, teleport, high ping, prediction off, and target switch.

Main UI revision 1: prediction controls are descriptor-backed `Nişan` rows; the view owns no prediction cadence. Verify conditional visibility and page cleanup.
