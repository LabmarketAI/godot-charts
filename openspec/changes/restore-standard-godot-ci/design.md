## Context

Run `30330189097` reproduces the same failures as the latest `main` run:

- `dotnet test` references ten C# implementation files already removed from
  the addon.
- `check-m1-boundaries.sh` calls unavailable `rg` from conditional commands,
  printing errors while incorrectly continuing.
- `test-visual-assets.sh` exits editor import after eight frames, before the
  official Godot runner necessarily writes the GLB import cache.

## Decisions

### Retire the orphaned managed test surface

The product runtime is standard Godot and the source files under test no longer
exist. CI will remove the .NET job and delete the unusable C# test project
instead of recreating removed implementations solely to satisfy stale tests.

### Make boundary scanning tool-portable

The audit will select `rg` when available and fall back to recursive extended
grep. Both paths retain line-numbered matches and nonzero no-match semantics.

### Wait for imports by contract

The visual-asset test will use Godot's `--import` command, which exits after the
editor import process completes. This replaces a timing guess without weakening
the subsequent cache and runtime-load assertions.

## Risks

- Grep and ripgrep have small regex differences. The audit patterns use the
  shared extended-regex subset and are covered by positive and negative shell
  checks.
- Removing NUnit coverage could lose behavior checks. Those implementations
  have already been removed; supported behavior remains covered by the
  standard-Godot suites.
