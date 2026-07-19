## Why

The active rebuild has established a pure typed-GDScript preview path, but the repository still carries legacy C#/.NET chart classes, demo project files, NUnit tests, NuGet dependency references, and documentation that describes Godot .NET setup as current behavior. This creates conflicting installation guidance, keeps CI tied to .NET, blocks clean standard-Godot packaging, and risks new work accidentally extending APIs that the product direction has already rejected.

The next porting slice needs a narrow contract: the installable addon, supported examples, WebXR template, packaging, and release gates must be standard-Godot typed GDScript. C# material can remain only as explicitly labeled historical migration evidence until it is deleted or archived outside the supported runtime surface.

## What Changes

- **BREAKING** Remove C#/.NET source files, wrappers, project files, NuGet package references, GodotSharp settings, and .NET-specific CI from the supported addon, examples, demo, packaging, and release documentation.
- Port or replace remaining supported behavior in typed GDScript, prioritizing public plotting, retained rendering, interactions, widgets/themes that remain in scope, and quantum-circuit loaders/renderers that are still product requirements.
- Delete unsupported legacy chart families rather than translating them one-for-one when the rebuild specification has no accepted retained-model contract for them.
- Replace `System.Text.Json` usage with Godot JSON plus schema/normalizer code owned by the GDScript protocol layer.
- Replace QuikGraph/MSAGL/MathNet usages with typed-GDScript implementations, dependency-approved optional integrations, or scoped removal backed by acceptance notes.
- Convert unit coverage from NUnit/.NET to standard-Godot headless GDScript tests and scriptable fixture checks.
- Update every public README, setup guide, headset/testing guide, packaging note, and contributor note so standard Godot is the default and Godot .NET appears only in historical audit material.
- Add automated repository gates that fail if supported runtime/export surfaces reintroduce `.cs`, `.csproj`, `.sln`, NuGet, Godot .NET, GodotSharp, QuikGraph, MSAGL, MathNet, or `System.Text.Json` references.

## Impact

- Primary impact: `addons/godot-charts/`, `demo/addons/godot-charts/`, `examples/`, `tests/`, `.github/workflows/`, `scripts/`, `packaging/`, and root/addon/demo documentation.
- The existing M1/M2/M3 typed-GDScript preview code becomes the canonical addon path instead of an allowlisted side package.
- Legacy docs under `docs/issue-*` and OpenSpec audit records may keep historical C# references if clearly labeled and excluded from current install/release guidance.
- CI will no longer use `dotnet test` as a required product gate. Any companion-side non-Godot code remains separate from the Godot addon and must not require Godot .NET.
- WebXR export gates become a first-class proof that the runtime addon contains no .NET, native-only, or unsupported C# artifacts.
