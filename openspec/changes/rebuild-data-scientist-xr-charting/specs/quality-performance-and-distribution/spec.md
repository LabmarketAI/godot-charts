## ADDED Requirements

### Requirement: Verified compatibility and packaging
Each release SHALL declare supported Godot versions, operating systems, renderers, and optional XR dependencies, and SHALL install and run as a pure typed-GDScript addon in standard Godot without .NET, NuGet, compilation, or mandatory native binaries.

#### Scenario: Clean install
- **WHEN** the release artifact is installed into each clean CI matrix project
- **THEN** the plugin loads, a documented minimal plot runs, and no demo-only dependency is required

#### Scenario: Standard Godot editor
- **WHEN** the addon is installed from its release artifact into a clean standard Godot project
- **THEN** it imports, enables, and renders the quickstart without C# support or network access

### Requirement: Dependency-first implementation gate
Before custom implementation of infrastructure or a non-differentiating capability, the project SHALL evaluate maintained existing Godot addons and relevant upstream packages. The evaluation SHALL record candidate source and version, semantic fit, maintenance status, license, security posture, API stability, platform and Godot compatibility, WebXR/web-export compatibility, binary and transitive dependencies, size/performance implications, and test evidence. The selected disposition SHALL be `adopt`, `wrap`, `optional integration`, or `build minimal`, and `build minimal` SHALL state the unmet contract that prevents reuse.

#### Scenario: Existing addon satisfies a capability
- **WHEN** a maintained compatible Godot addon satisfies the approved contract and release tiers
- **THEN** the project integrates it through the smallest stable adapter or configuration surface instead of implementing an equivalent subsystem

#### Scenario: Candidate requires a native binary
- **WHEN** a candidate package cannot run in standard Godot or WebXR because it requires a native binary
- **THEN** it is rejected for the baseline or isolated as an explicitly optional tier with declared fallback and does not leak its API into core contracts

### Requirement: Minimal owned integration code
Third-party packages SHALL be isolated behind project-owned interfaces at architectural boundaries, and integrations SHALL prefer configuration, composition, generated bindings, and upstream contributions over forks or duplicated implementations. Project-owned code SHALL focus on normalized plotting semantics, compatibility adaptation, spatial analytical behavior, and product-specific orchestration. Forks and vendored modifications SHALL require an owner, divergence rationale, update plan, and exit strategy.

#### Scenario: Upstream API changes
- **WHEN** an adopted package changes an internal API
- **THEN** only its bounded adapter and compatibility fixtures require change while public plot, data, frame, interaction, and backend contracts remain stable

### Requirement: Complete dependency disclosure
The repository SHALL keep machine-readable manifests or lockfiles for every applicable Godot, Python, native, web, build, test, and companion-service dependency and SHALL maintain a README dependency table. Every direct dependency SHALL declare purpose, source, supported or resolved version policy, license, bundled/required/optional/development scope, installation method, supported Godot/export/platform tiers, binary or service requirements, and fallback or removal behavior. Required notices and source obligations SHALL ship with releases, and undocumented runtime dependencies SHALL fail packaging review.

#### Scenario: Install an optional XR integration
- **WHEN** a user enables an optional XR package
- **THEN** the README and manifest identify the tested version, installation source, license, supported platforms/export targets, capabilities enabled, and behavior when it is absent

#### Scenario: Undeclared transitive runtime requirement
- **WHEN** a clean-install test discovers a package, binary, service, or network fetch not represented by the dependency inventory
- **THEN** the release gate fails until the dependency is declared, removed, or isolated behind an optional capability

### Requirement: Dependency maintenance and supply-chain review
Release automation SHALL verify pinned or constrained versions according to ecosystem practice, integrity/source policy where supported, license allowlist or review status, known-vulnerability disposition, compatibility fixtures, and unused-dependency removal. Updates SHALL be tested through the same public contract and platform matrix as custom code, and a critical dependency loss SHALL have a documented replace, disable, or minimal-fallback path.

#### Scenario: Dependency becomes unmaintained or vulnerable
- **WHEN** an adopted package no longer meets the recorded maintenance or security threshold
- **THEN** the affected release is blocked or the capability is replaced, patched upstream, disabled, or moved behind an acknowledged optional risk according to policy

### Requirement: Layered release gates
CI SHALL verify pure numerical contracts, public API examples, Godot scene lifecycle, representative visual output, interaction conformance, serialization migration, packaging, and smoke behavior before release.

#### Scenario: Public example drift
- **WHEN** a documented quickstart no longer compiles or renders its expected plot
- **THEN** the release pipeline fails

### Requirement: Published performance tiers
The project SHALL define and measure frame-time, update-latency, memory, and data-volume budgets for representative desktop and stereo-XR scenarios, including warm-up and degradation behavior.

#### Scenario: Exceed an XR budget
- **WHEN** a benchmark exceeds its approved stereo-XR budget beyond tolerance
- **THEN** CI reports the regression and the release cannot pass without an explicit budget revision

### Requirement: WebXR release target
Each WebXR-supported release SHALL declare tested Godot web export settings, browsers, headsets, reference spaces, input capabilities, feature fallbacks, data limits, and stereo performance tiers, and SHALL run without native binaries or .NET.

#### Scenario: WebXR smoke test
- **WHEN** the release gallery starts an immersive session on a supported browser/headset tier
- **THEN** a user can enter a spatial plot, inspect data, operate an analytical control, change an axis domain, and reset using the tier's baseline input
