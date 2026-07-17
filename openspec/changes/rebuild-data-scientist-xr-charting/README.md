# rebuild-data-scientist-xr-charting

Review the existing addon and define a rebuild path for a data-scientist-first, matplotlib/R-like Godot 3D and XR charting library.

**Milestone M1: Architectural Spine** is complete: a deterministic Python-originated scatter plot and bounded table render in clean standard Godot with stable identity, linked inspection/selection, incremental replacement, diagnostics, provenance, recorded/live transport parity, and a safe companion package.

**Milestone M2: Interactive Analytical Frame** is complete. The retained scatter is scientifically readable and spatially manipulable through retained guides, separate frame/content/navigation modes, reversible device-independent commands, desktop and mocked-XR adapters, and replay/live state-preservation tests. `m2-review.md` closes the bounded architecture and records the remaining accessibility, graphical-performance, native-XR, and WebXR risks.

**Milestone M3: WebXR-First Delivery Foundation** is selected. The primary production target is WebXR VR, with a simple non-immersive web mode delivered from the same Godot build. `specs/webxr-first-delivery/spec.md` defines the shared-build, secure-hosting, capability, fallback, and browser/headset certification contract. Production Jupyter discovery/authentication and additional chart families remain behind later explicit gates.

`m3-release-matrix.md` publishes the first measured flat-web candidate and the still-blocking physical-headset certification row. Until that row passes, the build is experimental and is not labeled WebXR-supported.
