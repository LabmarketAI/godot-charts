# Billboard Adoption

## ADDED Requirements

### Requirement: The addon serves billboard-scale charts
The addon SHALL provide compact multi-series line charts suitable for
in-world billboard surfaces - grouped series with titles, day-indexed
axes, legible at billboard resolution - covering the feature set
burb-sweeper's game-side billboard charts ship today.

#### Scenario: The game's charts have an addon equivalent
- **WHEN** the adoption reaches parity
- **THEN** each of burb-sweeper's billboard chart groups (stocks,
  population, ledger) renders through the addon with no visual
  regression

### Requirement: The boundary carries data, not game types
The addon SHALL accept plain series data - labels, points, group
metadata - at its boundary, with no consumer types imported; the
consumer's adapter (burb-sweeper's MetricSeriesAdapter) owns the
translation on its own side.

#### Scenario: Isolation holds both ways
- **WHEN** the addon is scanned for consumer references
- **THEN** none exist, mirroring the isolation guard burb-sweeper's
  portable cores enforce

### Requirement: Rendering is render-on-change friendly
Chart rendering SHALL support redraw-on-data-change usage so consumers
rendering to update-once viewport surfaces pay draw cost only when
content changes.

#### Scenario: The static chart costs nothing
- **WHEN** a chart's data is unchanged across frames
- **THEN** no per-frame redraw work is required of the consumer
