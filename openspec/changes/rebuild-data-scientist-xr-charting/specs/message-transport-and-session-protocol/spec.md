## ADDED Requirements

### Requirement: Transport-neutral session protocol
All message-bus integrations SHALL implement one versioned session protocol above the normalized plot/data/backend contracts. The protocol SHALL define connection handshake, peer and session identity, schema/capability negotiation, authentication attachment boundary, source discovery, subscriptions, commands, responses, events, errors, and orderly close without embedding transport-specific semantics in plot specifications.

#### Scenario: Connect through different transports
- **WHEN** recorded messages are delivered through in-process replay and a supported network bridge
- **THEN** the receiver observes equivalent identities, ordering, revisions, commands, errors, and analytical state

### Requirement: Ordering, idempotency, and resynchronization
The protocol SHALL define sequence scope, duplicate detection, revision preconditions, out-of-order behavior, gap detection, full-state resynchronization, and reset scope. Receivers SHALL apply complete valid revisions atomically and SHALL not partially mutate state after a protocol error.

#### Scenario: Detect a missing patch
- **WHEN** a receiver observes a revision gap
- **THEN** it preserves the last-good state, reports the gap, and requests or awaits a bounded full replacement according to negotiated policy

### Requirement: Liveness and reconnection
The protocol SHALL define heartbeat/liveness, idle policy, disconnect reason, retry/backoff guidance, session resumption, subscription restoration, authorization revalidation, and expired-handle behavior. Cached, stale, replayed, and live states SHALL be distinguishable.

#### Scenario: Resume after network loss
- **WHEN** a resumable connection returns
- **THEN** identity and authorization are revalidated and subscriptions resume from a negotiated point or full resynchronization occurs

### Requirement: Typed commands and cancellation
Commands SHALL carry stable command, request, actor, target, session, and correlation identities; arguments; permission and revision preconditions; deadline; confirmation status; and idempotency policy. Results, progress, cancellation, supersession, timeout, and late completion SHALL be explicitly correlated.

#### Scenario: Supersede a parameter query
- **WHEN** a newer committed parameter value supersedes an in-flight request
- **THEN** the prior request is cancelled or its late result is rejected without overwriting newer analytical state

### Requirement: Flow control and bounded payloads
Negotiation SHALL cover message, attachment, chunk, nesting, rate, queue, compression, and in-flight limits plus backpressure policy. Oversized datasets SHALL use bounded data requests or approved external attachment references rather than unbounded message fragmentation.

#### Scenario: Producer exceeds an agreed limit
- **WHEN** a producer sends an oversized or over-rate payload
- **THEN** the receiver rejects or defers it with a structured limit diagnostic and preserves service for other sources

### Requirement: Time and schema evolution
Timestamps SHALL identify clock source and interpretation, while ordering SHALL not depend on synchronized wall clocks. The protocol SHALL define supported-version ranges, feature negotiation, unknown-field behavior, deprecation periods, migration fixtures, and incompatible-version diagnostics.

#### Scenario: Connect incompatible schema versions
- **WHEN** peers share no compatible protocol/schema range
- **THEN** the connection fails safely with supported ranges and migration guidance rather than attempting partial interpretation

### Requirement: Secure transport observability
Protocol traces and dead-letter diagnostics SHALL be bounded, permission-controlled, and redacted. They SHALL preserve identifiers, message class, timing, size, status, and failure reason while excluding credentials and protected payload fields by policy.

#### Scenario: Export a connection trace
- **WHEN** a user creates an authorized support artifact
- **THEN** it contains enough correlation and negotiation evidence to reproduce the failure without including authentication material or undeclared analytical data
