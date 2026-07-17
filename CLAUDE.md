# Repository Guidance

## Product direction

`godot-charts` is being rebuilt as an installable, pure typed-GDScript Godot 4 addon for data-science visualization on desktop and in XR/WebXR. The target experience combines matplotlib/R-style analytical plotting with spatial inspection and manipulation. The active design and work tracker is `openspec/changes/rebuild-data-scientist-xr-charting/`.

## Current state

The repository is a migration project, not yet the target architecture:

- `addons/godot-charts/` is the canonical install path, but currently contains C# implementations and GDScript wrappers that require Godot .NET.
- `demo/` is a .NET reference application with demo-owned messaging, workspace, and frame services.
- `tests/` contains NUnit tests for selected C# helpers using Godot stubs.
- `.github/workflows/ci.yml` currently checks the duplicated demo addon and runs .NET tests; a standard-Godot GDScript lane is still required.

Do not describe the current addon or tests as pure GDScript/GdUnit4 until that migration is complete.

## Editing boundaries

- Edit canonical addon code only under `addons/godot-charts/`; never edit `demo/addons/godot-charts/` directly.
- Preserve existing legacy behavior until its replacement has fixtures or a recorded removal decision.
- New architectural-spine work must not extend C# classes or import demo-private services.
- Keep the release installable by copying one directory to `res://addons/godot-charts/`; do not add another project directory layer.
- Keep transports, Python/Jupyter, authentication, XR, GIS, and native acceleration behind optional integration boundaries.
- Use `bash scripts/sync-demo-addon.sh` only when a legacy/demo sync is intentionally needed.

## Target module boundaries

- `core`: scene-independent plot/table models, identity, validation, scales, and diffs.
- `protocol`: versioned envelopes, revisions, limits, diagnostics, and deterministic replay.
- `renderers`: Godot rendering and scene adapters.
- `interactions`: device-independent intents and linked analytical selection.
- `integrations`: optional backend, transport, XR, authentication, and GIS adapters.

The M1 gate is a recorded Python-originated scatter plot plus a bounded linked table, replayed offline in a clean standard-Godot project. See `legacy-audit.md`, `dependency-scorecard.md`, and `tasks.md` in the active OpenSpec change before implementing it.

## Verification during migration

Run the checks relevant to the touched surface:

```bash
bash scripts/check-demo-addon-sync.sh
dotnet test tests/GodotChartsTests.csproj --configuration Release
openspec validate rebuild-data-scientist-xr-charting --strict
```

The first two checks cover only the legacy implementation. New GDScript must gain standard-Godot headless tests and clean-install packaging checks as part of M1; passing the legacy NUnit suite is not proof of target-addon compatibility.
