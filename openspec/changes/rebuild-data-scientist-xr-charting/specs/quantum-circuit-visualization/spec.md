## ADDED Requirements

### Requirement: Qiskit object interchange
The companion Python package SHALL accept supported `qiskit.circuit.QuantumCircuit` objects and SHALL emit a JSON-safe normalized circuit payload inside the versioned plot-message envelope. The adapter SHALL record Qiskit/version provenance and SHALL use ordered circuit instructions and Qiskit's circuit-to-DAG conversion where dependency semantics are required.

#### Scenario: Publish a Qiskit circuit
- **WHEN** a producer submits a supported `QuantumCircuit` containing quantum and classical registers, gates, measurements, and symbolic parameters
- **THEN** the adapter publishes a normalized circuit plot whose identifiers and semantics resolve back to the source circuit, bits, and instructions

#### Scenario: Receive QPY
- **WHEN** a trusted Python integration receives a supported QPY circuit attachment
- **THEN** Qiskit loads it at the producer boundary and the adapter emits normalized JSON rather than requiring Godot to parse QPY

### Requirement: Faithful normalized circuit model
The circuit model SHALL preserve circuit name and metadata policy; quantum and classical registers and bit ordering; global phase; ordered instruction identity; operation name, label, parameters, symbolic expressions, operands, controls and modifiers; measurements; supported conditions and control-flow regions; barriers and directives; and available timing, physical-layout, calibration-summary, dependency, and layer metadata. Every omitted or approximated source feature SHALL produce a path-addressed diagnostic.

#### Scenario: Preserve measurement mapping
- **WHEN** an instruction measures a particular qubit into a particular classical bit
- **THEN** the model and rendered connector preserve both identities and expose them during inspection

#### Scenario: Preserve symbolic parameter
- **WHEN** a rotation gate contains an unbound Qiskit parameter expression
- **THEN** the expression, constituent parameter identities, display form, and binding status remain inspectable without coercion to an arbitrary float

#### Scenario: Unsupported custom operation
- **WHEN** a circuit contains a custom instruction the adapter cannot decompose or semantically classify
- **THEN** it is represented as an opaque labeled operation with operands and diagnostic rather than silently converted to a standard gate

### Requirement: Deterministic circuit dependencies and layout
The system SHALL preserve source instruction order and supplied dependency edges, SHALL compute deterministic valid layers when layers are absent, and SHALL distinguish logical execution order, drawable parallel layers, scheduled time, and physical hardware layout rather than conflating them.

#### Scenario: Parallel independent operations
- **WHEN** two operations have no quantum, classical, control-flow, or declared dependency conflict
- **THEN** a parallel-layer layout may place them together while retaining their source order as a separate property

#### Scenario: Conditional dependency
- **WHEN** an operation depends on a prior measurement through supported classical control
- **THEN** the dependency and condition are preserved and the operation is never laid out before its prerequisite

### Requirement: Circuit rendering as retained plot semantics
The Godot addon SHALL render circuits through retained views and circuit marks for wires, classical wires, gates, controls, targets, swaps, measurements, conditions, barriers/directives, groups, connectors, and labels. Marks SHALL retain picking identity and update incrementally without rebuilding unaffected instructions.

#### Scenario: Inspect a controlled gate
- **WHEN** a user points to or selects a controlled multi-qubit operation
- **THEN** the view identifies its operation, controls, targets, parameters, layer/time, source instruction, and dependencies

#### Scenario: Update a parameter binding
- **WHEN** a new revision changes one parameterized operation while circuit structure remains stable
- **THEN** that operation and affected guides update while unrelated marks and compatible selections retain identity

### Requirement: Honest spatial circuit views
The library SHALL provide a conventional wire-and-gate view and MAY provide dependency-expanded, scheduled-time, hardware-layout, comparison, or embodied spatial views only when the source data supplies the corresponding semantics. Every spatial axis, depth offset, color, size, and animation SHALL have an inspectable declared meaning and SHALL NOT imply quantum state, probability, fidelity, or timing that was not supplied.

#### Scenario: Stand within a circuit
- **WHEN** a user enters an embodied circuit view along its execution dimension
- **THEN** wire identity, execution direction, layer/time landmarks, gate labels, controls/targets, and a route to reset remain readable from inside the circuit

#### Scenario: Missing schedule information
- **WHEN** a circuit has logical layers but no scheduled start times or durations
- **THEN** the view labels its axis as logical order/layer and does not present spacing as physical time

### Requirement: Circuit analytical controls
Circuit views SHALL expose normalized controls for layer or time scrubbing, visible-range zoom, wire/register filtering, instruction inspection, dependency highlighting, expand/collapse of supported composite operations, parameter binding, comparison linking, and deterministic reset. Parameter manipulation SHALL emit a new analytical revision and SHALL NOT mutate the remote Python object implicitly.

#### Scenario: Scrub execution layers
- **WHEN** a user moves a desktop or world-space layer slider
- **THEN** the active layer and its causal context are highlighted with the exact layer value visible

#### Scenario: Manipulate a gate parameter
- **WHEN** a user changes an enabled rotation parameter through a handle
- **THEN** local normalized circuit state updates within declared bounds and emits a structured parameter-change event that an authorized integration may send back to Python

### Requirement: Circuit comparison and provenance
The library SHALL support linked comparison of related circuit revisions, including pre/post-transpilation circuits, when the producer supplies relationship and instruction/layout mapping metadata. Unmapped operations SHALL remain explicit.

#### Scenario: Compare transpilation revisions
- **WHEN** source and transpiled circuits arrive with a declared mapping
- **THEN** selecting a mapped instruction highlights its counterparts and physical qubits while unmatched or synthesized operations are identified as such

### Requirement: Circuit compatibility and regression fixtures
The project SHALL maintain supported-Qiskit-version fixtures covering standard and custom operations, symbolic parameters, quantum/classical registers, measurement, supported classical conditions/control flow, barriers/directives, physical layouts, transpiled circuits, and malformed or unsupported inputs.

#### Scenario: Qiskit upgrade
- **WHEN** the supported Qiskit version changes its circuit or DAG behavior
- **THEN** conformance tests detect semantic or layout differences before the compatibility matrix is updated
