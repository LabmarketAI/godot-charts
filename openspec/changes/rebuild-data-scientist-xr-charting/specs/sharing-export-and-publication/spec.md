## ADDED Requirements

### Requirement: Distinct publication artifacts
The workbench SHALL distinguish editable session bundles, immutable analytical snapshots, reconnectable deep links, rendered images/documents, exported data, spatial geometry, notebook embeddings, recordings/tours, and diagnostic support bundles. Each artifact SHALL declare schema/version, contents, provenance, permissions, sensitivity, portability, expiration, and live-versus-materialized behavior.

#### Scenario: Create a read-only snapshot
- **WHEN** a user publishes an immutable snapshot
- **THEN** it contains only approved materialized analytical state and metadata, cannot execute commands, and declares omitted live queries, links, or protected fields

### Requirement: Permission-separated export operations
View, copy, export-data, export-image/document, export-geometry, share-internal, share-external, and create-reconnectable-link SHALL be separate capabilities. Exporting a chart SHALL not implicitly authorize export of its source rows, queries, annotations, or credentials.

#### Scenario: Export an image without source data
- **WHEN** a user has image-export but not data-export permission
- **THEN** the rendered artifact may be produced with approved labels/provenance while embedded source data and reconnectable handles are excluded

### Requirement: Scientific and spatial formats
Supported releases SHALL declare fidelity and limitations for approved outputs such as PNG, stereo capture, SVG/PDF for compatible planar figures, CSV/Arrow for permitted tabular data, JSON/session bundles, and GLB/glTF for appropriate spatial geometry. Exports SHALL preserve units, scales, legends, annotations, and accessibility metadata where the format permits and diagnose semantic loss.

#### Scenario: Export a semantic 3D plot to GLB
- **WHEN** a permitted spatial view is exported as geometry
- **THEN** visual geometry and declared metadata are included within size limits while unsupported live controls and private data bindings are listed as omitted

### Requirement: Redaction, expiration, and revocation
Sharing SHALL support policy-driven removal or masking of credentials, endpoints, queries, sensitive parameters, row identities, source data, annotations, and provenance. Link/snapshot artifacts SHALL support declared audience, expiration, and revocation where hosted.

#### Scenario: Share outside an organization
- **WHEN** policy permits an external snapshot
- **THEN** the user previews its exact contents and omissions, confirms exposure and expiration, and can later identify and revoke the hosted artifact

### Requirement: Deterministic publication and provenance
Publication SHALL capture the producing application, schema, adapter/backend, data/plot revisions, theme/assets, fonts, locale/timezone, rendering tier, and approximation/fallback status needed to interpret or reproduce the artifact. Deterministic formats SHALL have regression fixtures.

#### Scenario: Reproduce a published figure
- **WHEN** compatible source revisions and dependencies remain available
- **THEN** the provenance manifest provides enough information to regenerate or explain differences from the published artifact
