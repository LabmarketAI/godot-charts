# M1 five-minute quickstart

Requirements: standard Godot 4.6.3 or newer, Bash for the preparation helper, and no .NET runtime.

```bash
./scripts/prepare-m1-example.sh /tmp/godot-charts-m1-example
```

Open `/tmp/godot-charts-m1-example/project.godot` in standard Godot and run the project. The scene displays the checked-in Matplotlib/pandas scatter inside a retained analytical frame with title and XYZ guides, alongside its bounded linked table. It pauses after the initial plot so `Space` visibly applies the compatible replacement revision without moving the frame or replacing its retained content.

Use `1`, `2`, and `3` for content, frame, and navigate modes. In frame mode, press `F` to select the frame, then `M` to begin moving or `B` to begin resizing. Arrow keys preview movement; `+`/`-` preview resize; `Enter` commits and `Escape` cancels back to the exact pre-preview state. Use `Z`/`Y` to undo/redo and `R` to restore authored state. The status line always reports the active revision, input mode, frame selection, capture, and rendered point count. Select table rows in content mode to highlight the corresponding scatter marks.

The prepared project is self-contained and uses only the generated preview addon, its public scripts, and recorded JSON fixtures. It does not load the legacy demo, C#, Python, a network connection, an XR package, or a live Jupyter kernel. The same frame controller is exercised by the separately tested mocked-XR adapter.
