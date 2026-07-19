## ADDED Requirements

### Requirement: Standard-Godot runtime only
The supported addon runtime SHALL load, run, test, and export in standard Godot using typed GDScript only. It SHALL NOT require Godot .NET, GodotSharp, C# source compilation, NuGet restore, `.csproj` or `.sln` files, or managed runtime artifacts.

#### Scenario: Install in standard Godot
- **WHEN** a user installs the supported addon into a clean standard-Godot project
- **THEN** the plugin enables and documented examples run without a .NET SDK, Godot .NET editor, NuGet restore, or C# build step

#### Scenario: Export WebXR
- **WHEN** CI exports the supported WebXR template from the declared Godot version
- **THEN** the generated web artifact contains no C# source, managed assemblies, NuGet metadata, GodotSharp project settings, or native-only managed runtime dependency

### Requirement: C# legacy removal policy
Legacy C# chart, widget, utility, circuit, demo, and test surfaces SHALL be ported to typed GDScript, removed, or archived as historical evidence. Supported runtime paths SHALL NOT expose C# classes as public API or keep two-line GDScript wrappers over C# implementations.

#### Scenario: Legacy class lacks accepted contract
- **WHEN** a legacy C# class does not map to an accepted retained-model plotting, interaction, circuit, or packaging contract
- **THEN** it is removed from the supported addon rather than translated one-for-one

#### Scenario: Historical note remains
- **WHEN** a legacy C# reference remains in an audit, issue note, or migration record
- **THEN** it is clearly labeled historical evidence and is excluded from install, release, and current setup guidance

### Requirement: Dependency replacement
The port SHALL remove baseline dependencies on QuikGraph, MSAGL, MathNet, `System.Text.Json`, and other .NET-only packages. Required behavior SHALL be implemented through typed GDScript, Godot APIs, existing protocol/schema layers, or explicitly approved optional integrations that do not leak into baseline addon contracts.

#### Scenario: Parse a plot message
- **WHEN** the addon receives a supported JSON plot or session message
- **THEN** it parses and validates the message through Godot-compatible GDScript code and structured diagnostics, not `System.Text.Json`

#### Scenario: Load a circuit fixture
- **WHEN** a supported quantum-circuit fixture is loaded
- **THEN** dependency ordering, validation, rendering metadata, and diagnostics are produced without QuikGraph or C# helpers

#### Scenario: Need a graph layout
- **WHEN** a legacy graph-network layout depends on MSAGL semantics
- **THEN** the baseline either removes that layout or uses an approved optional integration/fallback with documented capability limits instead of bundling MSAGL into the core addon

### Requirement: GDScript test and release gates
Release automation SHALL verify the port through standard-Godot headless GDScript tests, clean addon installation, example smoke tests, WebXR export checks, package audits, and forbidden-reference scans. Required CI SHALL NOT invoke `dotnet build` or `dotnet test` for the Godot addon.

#### Scenario: Forbidden reference reintroduced
- **WHEN** a supported runtime, example, packaging, CI, or current documentation path adds `.cs`, `.csproj`, `.sln`, NuGet, GodotSharp, Godot .NET, QuikGraph, MSAGL, MathNet, or `System.Text.Json`
- **THEN** the forbidden-reference gate fails unless the path is explicitly categorized as historical evidence

#### Scenario: Ported helper regresses
- **WHEN** a formerly C#-backed helper is ported to typed GDScript
- **THEN** a standard-Godot test fixture proves its accepted behavior, diagnostics, and failure modes before the C# source is removed

### Requirement: Documentation consistency
Current user, contributor, package, demo, example, and headset documentation SHALL present standard Godot plus typed GDScript as the supported path. Godot .NET instructions SHALL NOT appear in current quickstarts or release setup except as clearly marked historical migration notes.

#### Scenario: Read the addon README
- **WHEN** a user reads the current addon README
- **THEN** they see standard-Godot installation, test, and export instructions and are not told to install Godot .NET for supported functionality

#### Scenario: Review migration guidance
- **WHEN** a direct C# consumer reads the migration note
- **THEN** removed C# classes, supported GDScript replacements, intentionally unsupported features, and any temporary adapters are identified explicitly
