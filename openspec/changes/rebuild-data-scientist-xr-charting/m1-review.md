# M1 Exit Review

Status: accepted for M1 closure by product-owner continuation on 2026-07-16.

## Delivered vertical slice

The generated preview addon replays a deterministic Matplotlib/pandas 3D scatter plot and bounded table in standard Godot 4.6.3. It retains stable plot/view/layer/dataset/row identities, links table and chart selection, applies compatible replacement incrementally, diagnoses declared identity reset, exposes provenance and lifecycle diagnostics, and contains no C#, .NET project, native binary, network dependency, or demo-private API.

The public reference project is prepared with `scripts/prepare-m1-example.sh` and uses only the preview artifact plus recorded JSON fixtures. Remote GitHub Actions run `29549390094` proved the contract/model/render/table/session package gates; the reference-scene CI addition is pending its next pushed run.

## Measured evidence

| Gate | Result |
|---|---|
| Schema fixtures | 11 accepted; 1 declared-invalid fixture rejected |
| Rendered rows | 4 of 5; the missing positional row remains available in the table |
| Compatible scatter updates | 250 in approximately 10 ms headless on the development host |
| Bounded table refreshes | 250 in approximately 5 ms headless on the development host |
| Compatible lifecycle | Same frame transform, renderer node, MultiMesh resource, primitive IDs, table window, and eligible selection |
| Identity-breaking lifecycle | Same frame/resources/window; only invalid row-bound selection and picks reset with diagnostics |
| Standard engine | Official non-.NET Godot 4.6.3 Linux build passes |
| Clean artifact | Allowlist audit rejects C#/.NET/native/demo dependencies |

These headless measurements are regression budgets, not general desktop or XR capacity claims.

## Remaining risks and deferred scope

- The repository still carries the legacy mixed C#/GDScript addon beside the clean generated preview; migration/removal remains explicit future work.
- M1 has no live message transport, Jupyter authentication, backend discovery, XR input, WebXR export, GIS integration, quantum renderer port, compound figures, or additional chart families.
- Visual regression, label/axis rendering quality, accessibility evaluation, graphical GPU measurements, stereo budgets, and representative user testing remain later gates.
- The exhaustive legacy public-API/consumer inventory and owner decision on a compatibility adapter remain open under M1.1.
- Formal model/renderer/input/optional-integration boundary documentation and CI enforcement remain open under M1.2.
- The native headless SceneTree suite is the current GdUnit4 fallback; adopting GdUnit4 remains optional development work, not a runtime requirement.

## Review decision

The analytical spine, remaining M1.1/M1.2 governance work, and reference-scene CI are complete. Product-owner continuation accepted the documented risks and closes M1. This acceptance authorizes planning the next bounded vertical slice; it does not silently select a live transport, authentication mechanism, chart-family expansion, or XR/WebXR implementation without the corresponding dependency and capability gates.
