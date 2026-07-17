## ADDED Requirements

### Requirement: Typed tabular ingestion
The library SHALL ingest column-oriented and row-oriented tabular data through documented adapters, preserve column type and row identity where representable, and validate mappings before rendering.

#### Scenario: Ingest mixed columns
- **WHEN** a table contains numeric, categorical, temporal, and missing values
- **THEN** the adapter exposes their types, row identities, and missingness without stringifying the entire table

### Requirement: Declarative transformations
The plot model SHALL support deterministic, testable transformations needed by MVP plots, including filter, sort, bin, aggregate, and derived fields, while retaining provenance when mathematically possible.

#### Scenario: Histogram binning
- **WHEN** numeric observations are binned with an explicit boundary policy
- **THEN** every eligible observation belongs to exactly one reported bin and boundary behavior is reproducible

### Requirement: Bounded streaming updates
Streaming sources SHALL support append, replace, window, batch, and backpressure policies without forcing an unbounded queue or full plot rebuild for every observation.

#### Scenario: Producer exceeds render rate
- **WHEN** updates arrive faster than the configured render cadence
- **THEN** the declared coalescing or dropping policy is applied and exposes counts for deferred or dropped updates
