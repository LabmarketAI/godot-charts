## ADDED Requirements

### Requirement: First-class analytical table views
The workbench SHALL present tabular session data as first-class virtualized views rather than only bounded previews or charts. A table SHALL retain stable dataset, revision, column, index, and row identities and SHALL remain linkable to charts, selections, transformations, provenance, and compound figures.

#### Scenario: Inspect data before plotting
- **WHEN** a user opens a compatible DataFrame-like object
- **THEN** they can inspect typed columns, indexes, missing values, representative rows, revision, freshness, permissions, and provenance before choosing a visual mapping

### Requirement: Bounded tabular navigation
Table views SHALL request bounded pages or windows and SHALL support deterministic sort, filter, search, column projection, resize, reorder, pin, and row-detail operations without eagerly transferring the entire dataset. Operations SHALL execute locally or remotely according to declared capabilities and execution policy.

#### Scenario: Browse a large remote table
- **WHEN** a table exceeds local transfer or memory limits
- **THEN** navigation requests bounded row/column windows with cancellation, revision checks, and visible partial/loading state

### Requirement: Group, pivot, and summarize
Where advertised by the data or execution adapter, table views SHALL support grouping, aggregation, pivoting, binning, and column profiling with explicit transformation definitions, units, null handling, result limits, and provenance. Unsupported operations SHALL be absent or diagnosed rather than approximated silently.

#### Scenario: Pivot a table remotely
- **WHEN** a user confirms a pivot that the backend can execute more safely than Godot
- **THEN** the resulting table is registered as a derived data object with execution location, input revision, transformation, and limits recorded

### Requirement: Linked table and chart interaction
Tables and charts SHALL exchange normalized selections and filters through stable row or aggregate provenance. Selecting a permitted table row SHALL highlight related marks, and selecting chart marks SHALL permit focusing or materializing the corresponding authorized rows.

#### Scenario: Focus selected chart rows
- **WHEN** a chart selection resolves to source rows
- **THEN** an associated table can show those rows or a bounded derived selection without changing the source dataset

### Requirement: Complex dataframe semantics
Table views SHALL handle supported indexes, MultiIndex, hierarchical columns, categorical and nullable values, timezone-aware temporal values, decimals, duplicate labels, nested values, non-finite values, and extension types according to adapter capability and diagnostics.

#### Scenario: Display duplicate column labels
- **WHEN** a source table contains duplicate human-readable column names
- **THEN** stable column identities disambiguate mapping and selection without silently renaming the source schema

### Requirement: Permission-aware copy and export
Copying, materializing, or exporting displayed, selected, or full table data SHALL be separate capabilities with explicit scope, limits, redaction, and audit provenance. The UI SHALL distinguish visible-page export from full-dataset export.

#### Scenario: User may inspect but not export
- **WHEN** a user can view a table but lacks data-export permission
- **THEN** navigation and permitted inspection remain available while clipboard and export actions are unavailable and no bypass is offered through a chart selection
