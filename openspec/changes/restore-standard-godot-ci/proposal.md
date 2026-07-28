## Why

The required CI workflow is red on `main` for infrastructure that no longer
matches the supported standard-Godot runtime. The .NET lane compiles removed
C# sources, the boundary audit silently assumes `rg` exists on the runner, and
the visual-asset test gives asynchronous GLB imports only eight frames before
asserting on generated cache files.

These failures mask regressions and prevent otherwise valid chart changes from
reaching a green merge state.

## What Changes

- Remove the obsolete required .NET job and its orphaned C# test project.
- Keep the dependency-boundary audit effective on runners with either
  ripgrep or POSIX grep.
- Run Godot's explicit import-to-completion mode before checking GLB imports.
- Keep the packaged M1 example self-contained instead of copying retired demo
  floor assets that are no longer tracked.
- Preserve the standard-Godot contract, visual-asset validation, addon sync,
  and existing GDScript test coverage as required CI gates.

## Impact

- Primary impact: `.github/workflows/ci.yml`, `tests/`, `scripts/`, and the M1
  example scene.
- This is a CI-baseline repair, not a relaxation of runtime validation.
- The change advances the existing `remove-csharp-port-gdscript` direction by
  removing a dead .NET gate while retaining standard-Godot coverage.
