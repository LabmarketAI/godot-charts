## ADDED Requirements

### Requirement: Composable plot model
The library SHALL represent a plot as a versioned figure containing views, layers, data mappings, scales, guides, coordinates, theme, and interaction state, and SHALL allow a layer to be changed without reconstructing unrelated layers.

#### Scenario: Compose layers
- **WHEN** a user adds point and line layers mapped to the same columns
- **THEN** both layers share the declared scales and remain independently configurable

### Requirement: Familiar public facades
The library SHALL provide concise imperative and grammar-style typed-GDScript construction paths that compile to the same plot model, and SHALL expose supported behavior to C# consumers through Godot's standard GDScript interop without a duplicate C# implementation.

#### Scenario: Equivalent construction
- **WHEN** equivalent data and options are supplied through either facade
- **THEN** the normalized plot specifications are equivalent

#### Scenario: Consume from C#
- **WHEN** a C# scene in a Godot .NET consumer loads the addon and invokes its documented interop API
- **THEN** it creates the same normalized plot without compiling addon C# sources or restoring addon packages

### Requirement: Actionable validation and persistence
The library SHALL validate plot specifications before rendering, report errors with a path and remedy, and round-trip supported specifications through a versioned portable representation.

#### Scenario: Invalid mapping
- **WHEN** a layer maps an absent column to an encoding
- **THEN** validation identifies the layer, encoding, missing column, and available columns without mutating the active figure
