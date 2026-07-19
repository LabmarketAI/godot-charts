## Design Notes

### Boundary

The target is not a mechanical C#-to-GDScript transcription. The port must preserve accepted product contracts from the rebuild specification and the working typed-GDScript slices, while removing legacy behavior whose public contract has not been accepted.

Supported runtime surfaces are:

- `addons/godot-charts/`
- mirrored addon copies used by examples or demos
- public examples and WebXR template scenes
- packaging outputs
- release CI and install documentation

Historical evidence surfaces may retain C# references only when they are clearly marked as legacy evidence and are not copied into release artifacts, setup instructions, or current API examples.

### Replacement Policy

- Replace JSON parsing/validation through Godot `JSON`, typed dictionaries/resources, and existing schema/normalizer layers.
- Replace statistics helpers with small deterministic typed-GDScript routines only where the plotting contract requires them; otherwise move statistical work to companion adapters or source systems.
- Replace graph/circuit dependency ordering with minimal typed-GDScript algorithms where the circuit visualization contract requires them.
- Do not reimplement MSAGL-class graph layout as a baseline feature. If graph-network charting remains desirable, open a dependency-first follow-up with evidence for an optional layout integration or a minimal deterministic fallback.
- Keep C# interop only as consumer-side Godot script interop guidance. The addon must not ship a parallel C# implementation or require Godot .NET.

### Migration Approach

1. Inventory every C#/.NET reference and classify it as `port`, `remove`, `archive`, or `historical-evidence`.
2. Freeze the typed-GDScript public API needed by current examples and WebXR.
3. Port accepted runtime behavior behind existing GDScript contracts.
4. Delete unsupported C# runtime files and update mirrored addon copies.
5. Replace CI/doc gates so drift fails immediately.

### Compatibility

This change is intentionally breaking for consumers importing C# classes directly. The supported migration path is to consume typed-GDScript public APIs from standard Godot. If real external usage requires compatibility shims, those shims must be separate GDScript adapters with explicit deprecation and no .NET dependency.
