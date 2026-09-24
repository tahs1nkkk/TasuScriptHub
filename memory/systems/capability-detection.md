# System memory: executor capability detection

Capabilities include HTTP request paths, `loadstring`, file/folder APIs, custom asset loading, hidden UI parenting, input movement, touch/proximity helpers, and any executor-specific global used by a feature.

Resolve globals once through a normalized capability service. Feature code requests a capability and supplies a safe fallback or an explicit unsupported result.

Never add Studio substitutes. Capability results are included in diagnostics but must not expose sensitive executor data.

Executor checks: full-capability executor, missing file APIs, missing custom assets, missing request API with `game:HttpGet` fallback, and missing feature-specific helpers.

