## ADDED Requirements

### Requirement: Model-driven incremental rendering
The Godot renderer SHALL create and update scene resources from plot-model diffs, SHALL preserve unaffected render objects where practical, and SHALL release replaced resources without scene-tree leaks.

#### Scenario: Update one series
- **WHEN** one layer receives new values
- **THEN** unrelated layers, guides, and interaction state retain their identities and visible state

### Requirement: Renderer-neutral picking identity
Every inspectable visual primitive or aggregate SHALL expose a stable identifier that resolves to its layer and source rows without making input-device logic part of the renderer.

#### Scenario: Resolve a picked point
- **WHEN** the renderer returns a point primitive identifier
- **THEN** the library resolves its figure, view, layer, and source-row identity

### Requirement: Editor and runtime parity
Supported plots SHALL render from the same normalized specification in editor preview and at runtime, with documented exceptions for live or XR-only features.

#### Scenario: Preview a static plot
- **WHEN** a valid static plot resource is opened in the Godot editor
- **THEN** its marks and guides match the runtime baseline within the declared visual tolerance
