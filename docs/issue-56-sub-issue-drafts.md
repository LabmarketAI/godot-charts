# Issue 56 Sub-Issue Drafts

Parent issue: #56

Master checklist comment template: [docs/issue-56-master-checklist-comment.md](docs/issue-56-master-checklist-comment.md)

This file contains ready-to-paste child issue drafts for the implementation plan in [docs/issue-56-widget-library-implementation-plan.md](docs/issue-56-widget-library-implementation-plan.md).

---

## 1) RFC: Widget Architecture (Schema, Theme Tokens, Focus Model)

### Suggested title

RFC: Widget architecture for 3D/VR UI (schema + themes + focus)

### Suggested body

Parent: #56

## Summary

Define the baseline architecture for a Godot-native widget system that supports desktop and XR interaction, with declarative schema and theme tokens.

## Deliverables

1. Widget tree schema draft (component type, props, events, children).
2. Theme token schema draft (color, spacing, typography, radius, elevation, motion).
3. Focus and input model (desktop keyboard/mouse + XR pointer/ray precedence).
4. Architecture decision notes for layout constraints and rendering strategy.

## Acceptance criteria

1. RFC is published in docs and reviewed by maintainers.
2. Schema examples are included for at least two complex widget trees.
3. Focus rules cover keyboard, pointer, and XR ray interactions.
4. Open questions are explicitly listed with proposed defaults.

## Out of scope

1. Runtime widget implementation.
2. Importer or translator tooling.

---

## 2) Core: WidgetPanel3D and Layout Primitives

### Suggested title

Core: Implement WidgetPanel3D and base layout primitives

### Suggested body

Parent: #56

## Summary

Implement the core 3D panel host and layout primitives that all widgets will use.

## Deliverables

1. WidgetPanel3D base node for world-space UI mounting.
2. Layout primitives: row, column, grid, stack.
3. Basic size constraints and spacing behaviors.
4. Demo scene showing nested layouts inside a 3D panel.

## Acceptance criteria

1. Layout primitives compose predictably in nested hierarchies.
2. Layout behavior remains stable under panel resize.
3. Panel can be placed in world-space and remains interactable.
4. Demo scene documents expected layout outcomes.

## Out of scope

1. Complex controls (tables, trees, combobox).
2. Full responsive breakpoint engine.

---

## 3) MVP Controls: Button/Input/Toggle/Slider/Tabs/Modal/List

### Suggested title

MVP controls: implement first widget set for app panels

### Suggested body

Parent: #56

## Summary

Build the first production-usable control set for interactive application-style panels.

## Deliverables

1. Controls: button, text input, checkbox or toggle, slider, tabs, modal dialog, list item.
2. Shared states: default, hover, pressed, disabled, focused.
3. Shared event model: click, value changed, focus entered or exited.
4. Example scene with a functional settings panel.

## Acceptance criteria

1. All controls are keyboard and pointer operable on desktop.
2. Focus traversal is deterministic and documented.
3. Controls consume theme tokens rather than hardcoded styling.
4. Example scene demonstrates realistic interaction flow.

## Out of scope

1. Data table and tree widgets.
2. Rich text editor or advanced form validation.

---

## 4) XR Input: Pointer and Focus Manager Integration

### Suggested title

XR input: pointer, ray, and focus manager integration

### Suggested body

Parent: #56

## Summary

Integrate widget interaction with XR pointers and define conflict-free focus behavior between desktop and XR inputs.

## Deliverables

1. XR pointer or ray interaction bridge for widgets.
2. Unified focus manager with input precedence rules.
3. Visual focus feedback that is legible in VR.
4. Manual test checklist for common XR interaction flows.

## Acceptance criteria

1. XR pointer can activate all MVP controls.
2. No focus deadlock between keyboard focus and XR pointer focus.
3. Focus transitions are observable and repeatable.
4. Test checklist passes on at least one desktop and one XR path.

## Out of scope

1. Haptics tuning and gesture-only input.
2. Accessibility parity beyond focus visibility in this phase.

---

## 5) Demo: App-Style Panel Assembly Scene

### Suggested title

Demo: assemble an app-style panel from MVP widgets

### Suggested body

Parent: #56

## Summary

Create a reference demo scene that assembles MVP widgets into a realistic, task-driven app panel.

## Deliverables

1. Demo panel scene in world-space with representative workflows.
2. Example data bindings for list and modal interactions.
3. Scene documentation for desktop and XR usage paths.
4. Screenshots or recordings for issue and PR context.

## Acceptance criteria

1. Demo can be opened and exercised without custom setup.
2. Includes at least one multi-step interaction flow.
3. Demonstrates layout, state changes, and focus transitions.
4. Includes short usage notes in docs.

## Out of scope

1. Production business logic integration.
2. Advanced analytics or telemetry.

---

## 6) Theme System: Two Presets + Runtime Switching

### Suggested title

Theme engine: tokenized styling with runtime theme switching

### Suggested body

Parent: #56

## Summary

Implement token-driven styling and provide at least two complete theme presets.

## Deliverables

1. Token model for color, spacing, typography, radius, elevation, motion.
2. Two complete presets (for example neutral and high-contrast).
3. Runtime theme switching API.
4. Demo scene that toggles themes live.

## Acceptance criteria

1. MVP controls consume tokens from active theme.
2. Theme switching updates visible styles without scene reload.
3. Missing token fallback behavior is defined and tested.
4. Theme authoring docs include minimal examples.

## Out of scope

1. Full design-tool export integration.
2. Unlimited theme inheritance layers.

---

## 7) Tooling: Schema Validator and Importer Scaffolding

### Suggested title

Tooling: add schema validator and importer scaffolding

### Suggested body

Parent: #56

## Summary

Set up foundational tooling to validate widget schema and prepare import workflows.

## Deliverables

1. Validator for widget tree schema and theme token schema.
2. Importer scaffolding that converts schema assets into runtime structures.
3. Clear error reporting for invalid schema fields.
4. Sample valid and invalid fixture files.

## Acceptance criteria

1. Validator catches required-field and type errors.
2. Error messages identify exact schema path and reason.
3. Importer scaffolding can ingest a simple widget tree.
4. Fixtures are included and documented.

## Out of scope

1. Full external-library translation.
2. Automatic migration between schema versions.

---

## 8) Translator v1: Curated External Component Source

### Suggested title

Translator v1: convert curated external component specs to widget schema

### Suggested body

Parent: #56

## Summary

Build the first translator pass that maps a curated external component definition set into the internal widget schema.

## Deliverables

1. Curated source format selection and mapping rules.
2. Translator script or tool entry point.
3. At least one end-to-end translated component family.
4. Mapping coverage report and known gaps list.

## Acceptance criteria

1. Translator produces valid schema files accepted by validator.
2. Generated widgets render in a demo scene with expected structure.
3. Unsupported features are surfaced with explicit warnings.
4. Documentation explains how to run translator and inspect output.

## Out of scope

1. Full parity with web CSS or DOM semantics.
2. Automatic translation of arbitrary third-party codebases.

---

## 9) Performance: Benchmark Scene and Baseline Metrics

### Suggested title

Performance: benchmark widget runtime and define baseline metrics

### Suggested body

Parent: #56

## Summary

Establish repeatable performance benchmarks for widget-heavy scenes in desktop and XR paths.

## Deliverables

1. Benchmark scene with scalable widget count and interaction load.
2. Baseline metrics: frame time, draw calls, update costs.
3. Stress thresholds and recommended limits.
4. Simple performance regression checklist for PR review.

## Acceptance criteria

1. Metrics can be reproduced with documented test steps.
2. Baseline numbers are recorded in docs.
3. At least one optimization recommendation is captured.
4. Regression checklist is referenced in contributor workflow.

## Out of scope

1. Engine-level renderer optimization.
2. Platform-specific profiling beyond initial targets.

---

## 10) Compliance: License and Attribution CI Checks

### Suggested title

Compliance: add license and attribution checks for imported assets

### Suggested body

Parent: #56

## Summary

Add compliance guardrails for any imported inspiration assets, specs, or code fragments.

## Deliverables

1. Dependency and attribution manifest template.
2. CI check for unknown or disallowed licenses in relevant paths.
3. Documentation for acceptable license classes and attribution policy.
4. Contributor checklist updates for import workflows.

## Acceptance criteria

1. CI fails when disallowed or missing license metadata is detected.
2. Manifest format is documented and easy to update.
3. Policy clearly distinguishes inspiration vs copied implementation.
4. Existing imported references are cataloged in the manifest.

## Out of scope

1. Legal opinion automation.
2. Non-repository dependency scanning outside project scope.
