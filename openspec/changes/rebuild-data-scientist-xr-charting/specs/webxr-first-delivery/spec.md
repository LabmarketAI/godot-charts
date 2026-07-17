## ADDED Requirements

### Requirement: WebXR-first product delivery
The primary production delivery SHALL be a Godot web export that enters immersive VR through WebXR on supported browsers and headsets. The same URL and build SHALL also provide a simple non-immersive browser mode when WebXR is unavailable, unsupported, denied, or not requested. WebXR and flat-web presentation SHALL share normalized plot, frame, selection, command, session, provenance, and persistence semantics rather than becoming separate applications.

#### Scenario: Enter immersive analysis
- **WHEN** a supported browser reports an immersive VR session and the user explicitly requests entry
- **THEN** the application enters WebXR, selects a supported reference space, presents the retained analytical frame at a comfortable authored pose and scale, and enables the baseline ray/select interaction path

#### Scenario: Continue without immersive support
- **WHEN** WebXR is unavailable, session creation fails, permission is denied, or the user chooses not to enter VR
- **THEN** the same build remains usable as a simple web application with camera navigation, inspection, row selection, frame manipulation, reset, diagnostics, and an explanation of unavailable immersive capabilities

#### Scenario: Leave an immersive session
- **WHEN** an immersive session ends normally or is lost
- **THEN** uncommitted capture follows the declared cancellation policy, analytical and committed frame state remain valid, and the application returns to flat-web mode without reloading or losing the current plot revision

### Requirement: Reproducible Godot web export
The release SHALL export from the declared standard Godot version through a committed `Web` preset using the Compatibility renderer, WebGL 2.0, pure GDScript, and no mandatory native binary, .NET runtime, GDExtension, or thread dependency. CI SHALL perform a release export and verify the generated HTML, JavaScript, WebAssembly, and pack artifacts before deployment.

#### Scenario: Build the browser release
- **WHEN** CI runs the documented web build command with the matching official Godot export templates
- **THEN** export completes without script, resource, plugin, or unsupported-renderer errors and emits a self-contained `index.html` build whose companion artifacts retain their generated basename

#### Scenario: Reject a non-web-compatible dependency
- **WHEN** the release artifact contains C#, a native-only extension, a demo-private import, or a Forward+/Mobile-only rendering requirement
- **THEN** the WebXR/flat-web build gate fails before publication

### Requirement: Secure browser hosting contract
Production hosting SHALL use HTTPS, except for standards-permitted localhost development, and SHALL declare the response headers, content types, caching, WebSocket endpoints, CORS policy, and Content Security Policy required by the selected Godot export and WebXR browser matrix. Credentials SHALL not be embedded in exported resources, URLs, service-worker caches, logs, or ordinary client persistence.

#### Scenario: Load from production hosting
- **WHEN** a user opens the release URL
- **THEN** HTML, JavaScript, WebAssembly, and pack resources load with correct content types over a secure context and the browser can request WebXR without mixed-content or origin-policy violations

#### Scenario: Connect to a live analytical session
- **WHEN** the web build connects to an authorized companion endpoint
- **THEN** it uses browser-supported HTTPS/WSS routes subject to explicit origin policy, reports blocked or unreachable routes without losing recorded/offline functionality, and never bypasses browser security controls

### Requirement: Baseline single-threaded web tier
The baseline flat-web and WebXR build SHALL be single-threaded and SHALL disable extension support unless measurements and compatibility evidence authorize a separate enhanced tier. This baseline SHALL not require `SharedArrayBuffer` or cross-origin isolation. Any future threaded or extension-enabled tier SHALL be separately named, hosted, measured, and provided with a baseline fallback.

#### Scenario: Host the baseline on a simple static server
- **WHEN** the baseline build is served over HTTPS without cross-origin isolation headers
- **THEN** it starts in flat-web mode and may enter WebXR on a supported secure-context browser without requiring thread or extension features

### Requirement: Runtime capability negotiation
The application SHALL detect WebXR availability, immersive session support, reference spaces, input-source profiles, controller pose/select, squeeze/grab, hand tracking, touch, keyboard, mouse, and relevant browser limitations at runtime. Ray/select SHALL be the minimum immersive interaction capability; hand tracking and squeeze/grab SHALL be progressive enhancements.

#### Scenario: Headset supplies controllers but no hands
- **WHEN** immersive VR provides pose, ray, and select inputs without hand tracking
- **THEN** all release-critical workflows remain operable through ray/select and no control requires a hand-only gesture

#### Scenario: Browser has no WebXR
- **WHEN** the application runs in a WebGL 2.0 browser without WebXR
- **THEN** it selects the flat-web adapter, keeps all supported analytical state readable, and does not present failed immersive initialization as an application failure

### Requirement: Shared responsive web presentation
The simple web version SHALL use the same scene and public APIs with a responsive canvas and accessible HTML/canvas-adjacent entry, status, help, and fallback presentation. Desktop web input SHALL support keyboard and pointer operation without requiring an XR device, and critical state SHALL have a textual alternative.

#### Scenario: Use the application on a laptop
- **WHEN** a user opens the release in a supported desktop browser
- **THEN** the canvas fits the available viewport, the user can operate the documented content/frame/navigation workflow with keyboard and pointer input, and title, status, controls, and selected values remain readable

### Requirement: Browser and headset release matrix
Every release SHALL publish the exact Godot version, web preset, deployment configuration, tested browsers and versions, headset/runtime tiers, reference spaces, baseline and enhanced inputs, known limitations, content limits, and measured mono/stereo budgets. A successful file export alone SHALL not be treated as WebXR runtime certification.

#### Scenario: Publish a WebXR release candidate
- **WHEN** a release candidate has not passed the declared browser flat-web smoke tests and at least one representative WebXR headset tier
- **THEN** it may be distributed as an experimental build but SHALL not be labeled a supported WebXR release
