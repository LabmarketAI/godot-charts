## 1. Inventory and Decisions

- [ ] 1.1 Generate a repository inventory of `.cs`, `.csproj`, `.sln`, GodotSharp, NuGet, `dotnet`, QuikGraph, MSAGL, MathNet, and `System.Text.Json` references outside OpenSpec audit/history files.
- [ ] 1.2 Classify each reference as `port`, `remove`, `archive`, or `historical-evidence`, with owner-approved rationale and target replacement path.
- [ ] 1.3 Define the supported runtime/doc paths where C#/.NET references are forbidden and the historical paths where they may remain with explicit legacy labeling.

## 2. GDScript Runtime Port

- [ ] 2.1 Remove legacy C# chart nodes and wrappers from the supported addon once equivalent accepted retained-model GDScript behavior exists or the chart family is declared out of scope.
- [ ] 2.2 Port accepted widget/theme/schema helper behavior to typed GDScript or remove it from the supported addon if it is not part of the current plotting contract.
- [ ] 2.3 Port accepted circuit loading, validation, dependency layering, and rendering behavior to typed GDScript without QuikGraph or `System.Text.Json`.
- [ ] 2.4 Replace MathNet-backed statistics with minimal deterministic GDScript routines only where required by retained plot contracts; otherwise document source-side computation as the supported path.
- [ ] 2.5 Ensure `addons/godot-charts/`, mirrored addon copies, examples, and WebXR template scenes load in standard Godot with no .NET feature flags.

## 3. Tests and CI

- [ ] 3.1 Convert remaining NUnit/.NET tests into standard-Godot headless GDScript tests or companion-side non-Godot tests where appropriate.
- [ ] 3.2 Remove required `dotnet build` and `dotnet test` lanes from CI after equivalent GDScript gates exist.
- [ ] 3.3 Add a strict forbidden-reference gate for supported runtime/export/doc paths.
- [ ] 3.4 Add clean standard-Godot install, example launch, WebXR export, addon sync, and packaging checks proving no C#/.NET artifacts are required.
- [ ] 3.5 Add regression fixtures for each ported behavior and deletion evidence for each removed unsupported legacy surface.

## 4. Documentation and Packaging

- [ ] 4.1 Update root, addon, demo, example, WebXR, packaging, contributor, and headset-testing docs so standard Godot typed GDScript is the only current runtime path.
- [ ] 4.2 Move or relabel legacy .NET setup docs as historical migration evidence, not current user guidance.
- [ ] 4.3 Remove C#/.NET artifacts from release packaging allowlists, install scripts, and generated preview packages.
- [ ] 4.4 Publish a migration note for direct C# consumers explaining removed classes, supported GDScript replacements, and any intentionally unsupported legacy features.
- [ ] 4.5 Update OpenSpec progress and acceptance evidence with the final inventory, port/removal decisions, CI run, and packaging artifact proof.

## 5. Acceptance

- [ ] 5.1 `rg` over supported runtime/export/doc paths finds no forbidden C#/.NET runtime references.
- [ ] 5.2 A clean standard-Godot project installs the addon, enables the plugin, runs the reference scene, and exports the WebXR template without Godot .NET or NuGet.
- [ ] 5.3 CI passes without any required `dotnet` invocation.
- [ ] 5.4 Release docs and package metadata no longer tell users to install Godot .NET for supported charting paths.
- [ ] 5.5 Historical C# references that remain are explicitly labeled, excluded from release artifacts, and covered by the forbidden-reference allowlist.
