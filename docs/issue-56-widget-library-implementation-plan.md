# Issue 56: Open-Source/MIT Widget Library Investigation Plan

Related issue: https://github.com/LabmarketAI/godot-charts/issues/56

Sub-issue drafts: [docs/issue-56-sub-issue-drafts.md](docs/issue-56-sub-issue-drafts.md)

## Goal

Enable a reusable 3D/VR-friendly widget system for application-style interfaces in Godot, while preferring open-source and permissive-licensed building blocks over custom-from-scratch implementations.

## Scope

This phase is focused on:

1. Selecting a practical base toolkit strategy for Godot-native widgets.
2. Defining a translation pipeline from web-style component specs to Godot scenes.
3. Shipping a minimal but useful widget set for in-world UI panels.

Not in scope for the first delivery:

1. Full parity with React/HTML/CSS runtimes.
2. Browser-engine embedding as the default rendering path.
3. Pixel-perfect cloning of Material/Bootstrap/Shadcn visual systems.

## Constraints and Requirements

1. Widgets must work in 3D and VR contexts (diegetic panels and world-space placement).
2. Licensing must be permissive (MIT/BSD/Apache-2.0 preferred).
3. Runtime performance must remain stable for multiple active panels in a scene.
4. Styling must be themeable and data-driven, not hardcoded per widget.

## Candidate Ecosystem Review

### A. Direct web library port (React + CSS stack)

Pros:

1. Large component ecosystem.
2. Mature design language options.

Cons:

1. Requires emulating DOM/CSS layout behavior in Godot.
2. High complexity for focus, accessibility, input routing, and animation parity.
3. Risk of becoming a partial browser framework inside a game engine.

Recommendation:

Use as inspiration/spec source only, not as a direct port target.

### B. Godot-native widget layer inspired by web design systems

Pros:

1. Native performance and input handling.
2. Better 3D integration and XR interaction control.
3. Easier packaging for addon distribution.

Cons:

1. Requires initial component implementation effort.
2. Theme/token mapping needs deliberate architecture.

Recommendation:

Primary strategy for issue 56.

### C. Hybrid: declarative schema + Godot renderer

Pros:

1. Supports import from open-source component metadata.
2. Keeps rendering native while allowing external design workflows.

Cons:

1. Requires schema governance and importer tooling.

Recommendation:

Adopt in phase 2 after baseline native widgets exist.

## Proposed Architecture

### 1. Core packages

1. Widget runtime package
   - Base controls (button, input, toggle, slider, tabs, dropdown, modal, list, table shell).
   - State model and event signals.
2. Layout package
   - Row/column/grid/stack containers.
   - Responsive rules based on panel size classes.
3. Theme/token package
   - Color, typography, spacing, radius, elevation, animation tokens.
   - Theme switching at runtime.
4. XR interaction package
   - Pointer, ray, grab, keyboard focus handoff.
   - World-space input affordance profiles.
5. Import/export tooling package
   - JSON schema for widget trees and style tokens.
   - Translator from curated external component specs into schema.

### 2. Render model

1. Scene tree based controls using Godot Control/Node3D composition.
2. A WidgetPanel3D wrapper for anchoring UI in world-space.
3. Material + shader hooks for panel surfaces and hover/focus effects.

### 3. Data and config contracts

1. Widget tree JSON schema (component type, props, events, children).
2. Theme token JSON schema (semantic color + spacing + typography scales).
3. Variant contract (density, contrast, XR-target-size profile).

## Implementation Phases

### Phase 0: Research + Design Baseline

Deliverables:

1. License-vetted candidate list and component taxonomy.
2. Widget schema draft and theme token draft.
3. Input/focus behavior spec for desktop + XR.

Exit criteria:

1. Team agreement on architecture and first component set.

### Phase 1: MVP Godot-native Widget Set

Deliverables:

1. Core controls: button, text input, checkbox/toggle, slider, tabs, modal, list item.
2. Layout primitives: row, column, grid.
3. Theme engine with at least two presets.
4. Demo scene with desktop + XR interaction.

Exit criteria:

1. Widgets usable for a basic in-world settings panel.
2. Runtime performance acceptable with multiple panels.

### Phase 2: Translation Tooling

Deliverables:

1. CLI/tool script to convert curated external component definitions to widget schema.
2. Import pipeline generating Godot scene/resource representations.
3. Validation/lint for schema and token files.

Exit criteria:

1. At least one external component family translated end-to-end.

### Phase 3: Advanced Component Coverage

Deliverables:

1. Data table, tree view, form validation primitives, rich dropdown/combobox.
2. Animation and transition presets mapped from design tokens.
3. Accessibility improvements (focus visibility, keyboard navigation consistency).

Exit criteria:

1. Complex app-like panels are practical without bespoke controls.

## Technical Risks and Mitigations

1. Risk: CSS-like layout parity becomes a rabbit hole.
   - Mitigation: Keep schema declarative but map to a constrained Godot-first layout model.
2. Risk: XR input conflicts between pointer and keyboard focus.
   - Mitigation: Define explicit focus manager and input precedence rules early.
3. Risk: Theme drift across components.
   - Mitigation: Token-only styling policy with component-level lint checks.
4. Risk: Performance regressions with large widget trees.
   - Mitigation: Virtualization for long lists/tables and pooled component instances.

## Open-Source Compliance Process

1. Maintain a dependency/license manifest for all imported inspirations/assets.
2. Restrict code copying to permissive licenses with attribution notes.
3. Prefer reimplementation from behavioral specs over direct source transplantation.
4. Add CI check that flags unknown or disallowed licenses in vendor folders.

## Proposed Sub-Issues

1. Create widget architecture RFC (schema + theme token spec + focus model).
2. Implement WidgetPanel3D base and layout primitives.
3. Implement MVP controls (button/input/toggle/slider/tabs/modal/list).
4. Implement XR pointer + focus manager integration.
5. Build demo scene: app-style panel assembled from MVP controls.
6. Add theme system with two presets and runtime switching.
7. Add schema validator + importer scaffolding.
8. Build first external component translator (curated source set).
9. Add performance benchmark scene and baseline metrics.
10. Add license/compliance CI checks for imported assets/specs.

## Definition of Done for Issue 56

Issue 56 can be considered complete when:

1. The implementation plan is reviewed and accepted.
2. Sub-issues are created from the list above.
3. A follow-up milestone is agreed for Phase 1 MVP delivery.
