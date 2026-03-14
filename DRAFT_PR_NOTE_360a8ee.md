# Draft PR Note - 360a8ee

## Title
Fix hand blend tree node connection order

## Commit
- SHA: 360a8ee
- Repository: LabmarketAI/godot-charts
- Branch: main

## Summary
This change updates left/right hand AnimationNodeBlendTree resources so the output connection ordering is normalized.

## Files Changed
- demo/addons/godot-xr-tools/hands/animations/left/hand_blend_tree.tres
- demo/addons/godot-xr-tools/hands/animations/right/hand_blend_tree.tres

## Risk Assessment
Low. Resource graph wiring change only; no C# or GDExtension runtime code changed.

## Validation
- Local diff scope reviewed: only 2 blend tree files changed.

## CI Status (as of 2026-03-13)
- Unit Tests (.NET): skipped
- Addon Sync Check: failure
- Workflow URL: https://github.com/LabmarketAI/godot-charts/actions/runs/23076681433

## Follow-up Actions
1. Investigate and fix Addon Sync Check failure.
2. Re-run workflow until all checks are green.
3. Smoke test hand grip/trigger animation transitions in demo scene.
