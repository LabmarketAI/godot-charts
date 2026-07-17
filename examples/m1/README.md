# M1 five-minute quickstart

Requirements: standard Godot 4.6.3 or newer, Bash for the preparation helper, and no .NET runtime.

```bash
./scripts/prepare-m1-example.sh /tmp/godot-charts-m1-example
```

Open `/tmp/godot-charts-m1-example/project.godot` in standard Godot and run the project. The scene replays the checked-in Matplotlib/pandas session, displays the missing-aware 3D scatter plot and bounded table, and reports the active plot revision. Select table rows to highlight the corresponding scatter marks.

The prepared project is self-contained and uses only the generated preview addon, its public scripts, and recorded JSON fixtures. It does not load the legacy demo, C#, Python, a network connection, or a live Jupyter kernel.
