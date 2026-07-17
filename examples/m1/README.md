# M1 five-minute quickstart

Requirements: standard Godot 4.6.3 or newer, Bash for the preparation helper, and no .NET runtime.

```bash
./scripts/prepare-m1-example.sh /tmp/godot-charts-m1-example
```

Open `/tmp/godot-charts-m1-example/project.godot` in standard Godot and run the project. The scene displays the checked-in Matplotlib/pandas scatter inside a retained analytical frame with title and XYZ guides, alongside its bounded linked table. It pauses after the initial plot so `Space` visibly applies the compatible replacement revision without moving the frame or replacing its retained content.

Use `1`, `2`, and `3` for content, frame, and navigate modes. Navigate mode provides `W`/`A`/`S`/`D` camera motion plus `Q`/`E` down/up. In frame mode, press `F` to select the frame, then `M` to begin moving or `B` to begin resizing. Arrow keys preview movement; `+`/`-` preview resize; `Enter` commits and `Escape` cancels back to the exact pre-preview state. Use `Z`/`Y` to undo/redo and `R` to restore authored state. A persistent on-screen control legend remains visible even when the table has focus, and the status line reports the active revision, input mode, frame selection, capture, and rendered point count. Select table rows in content mode to highlight the corresponding scatter marks.

The same workflow is available through focusable on-screen buttons for pointer-only use. At narrow browser widths the linked table moves below the visualization, while status, help, and WebXR availability remain textual and visible. This pointer surface is deliberately complete for the current reference workflow rather than merely providing an `Enter VR` button around a keyboard-only application.

The prepared project is self-contained and uses only the generated preview addon, its public scripts, and recorded JSON fixtures. It does not load the legacy demo, C#, Python, a network connection, an XR package, or a live Jupyter kernel. The same frame controller is exercised by the separately tested mocked-XR adapter.

The same project is the baseline browser build and uses Godot's Compatibility renderer. With the matching Godot 4.6.3 export templates installed, run `GODOT_BIN=/path/to/godot scripts/build-web-example.sh /tmp/godot-charts-web` from the repository root. The committed `Web` preset produces a single-threaded, extension-free `index.html`/JavaScript/WebAssembly/PCK release that does not require cross-origin isolation. Serve it from HTTPS for production WebXR. On a supported browser/headset, the visible `Enter VR` button starts an immersive session from the required user gesture and becomes `Exit VR`; ending or losing the session restores the desktop camera without replacing analytical state. Flat-web keyboard operation remains active when immersive VR is unavailable or not requested.

For physical device certification, follow [Testing the WebXR build on a headset](../../docs/webxr-headset-testing.md). The runbook covers trusted HTTPS deployment, the current two-select frame workflow, exit and capability-loss recovery, stereo/latency/memory measurements, the 15-minute thermal check, troubleshooting, and the evidence required to complete M3.7.
