## ADDED Requirements

### Requirement: Scientific scale semantics
The library SHALL provide deterministic continuous, categorical, temporal, logarithmic, and three-dimensional spatial scales with explicit domain, range, clamping, inversion, and invalid-value behavior.

#### Scenario: Invalid logarithmic domain
- **WHEN** a logarithmic scale receives zero or negative values without an explicit handling policy
- **THEN** the library reports a validation error rather than silently plotting misleading values

### Requirement: Accurate guides
The library SHALL derive stable axes, ticks, labels, grids, and legends from scales while allowing user overrides and locale-aware formatting.

#### Scenario: Stable tick generation
- **WHEN** the same domain, viewport, locale, and tick policy are rendered repeatedly
- **THEN** tick values, ordering, and formatted labels are identical

### Requirement: Missing and non-finite values
The library SHALL distinguish missing, NaN, and infinite values and SHALL apply a documented per-mark policy without changing valid observations.

#### Scenario: Gap in a line
- **WHEN** a line series contains a missing value under the default policy
- **THEN** the rendered line contains a gap and inspection can report the omitted observation
