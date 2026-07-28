## ADDED Requirements

### Requirement: Required CI matches the supported runtime
Required CI SHALL test the supported standard-Godot typed-GDScript runtime and
SHALL NOT invoke an orphaned .NET test project whose implementation sources are
absent.

#### Scenario: CI runs after the C# runtime is removed
- **WHEN** the repository no longer contains the C# implementations named by
  the legacy NUnit project
- **THEN** required CI runs the standard-Godot gates without restoring or
  compiling those removed implementations

### Requirement: Boundary audits fail reliably on hosted runners
The dependency-boundary audit SHALL scan all declared addon layers whether or
not ripgrep is installed, and SHALL fail when a forbidden dependency is found.

#### Scenario: Ripgrep is unavailable
- **WHEN** the boundary audit runs with no `rg` executable on `PATH`
- **THEN** it uses a ubiquitous fallback scanner and preserves pass/fail
  behavior

#### Scenario: A forbidden dependency is present
- **WHEN** a scanned layer imports a forbidden addon surface
- **THEN** the audit exits nonzero and identifies the violating line

### Requirement: Visual imports are completion-based
Visual-asset CI SHALL wait for Godot's import operation to complete before
asserting that imported GLB cache artifacts exist.

#### Scenario: GLB import takes more than eight frames
- **WHEN** the hosted runner imports the packaged GLB asynchronously
- **THEN** the test waits for editor import completion and validates both the
  generated cache and runtime resource load

### Requirement: CI examples are self-contained
Packaged CI examples SHALL reference only tracked source assets or resources
authored directly in their Godot scenes.

#### Scenario: Prepare the M1 example from a clean checkout
- **WHEN** the example preparation script runs without retired demo assets
- **THEN** it creates a loadable project with an editor-visible floor and no
  missing-file copy operation
