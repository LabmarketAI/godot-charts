# Translator v1 — Mapping Coverage Report

Parent issue: #64
Source format: material-design-simplified v1.0
Internal schema: widget schema v1.0

---

## How to run the translator

The translator is a pure C# static class (`GodotCharts.WidgetSpecTranslator`) with no Godot runtime dependency. It can be called from any C# context:

```csharp
string specJson = File.ReadAllText("my_component_spec.json");
TranslationResult result = WidgetSpecTranslator.Translate(specJson);

// Inspect warnings
foreach (var w in result.Warnings)
    Console.WriteLine($"[WARN] {w}");

// Serialize and validate each descriptor
foreach (var desc in result.Descriptors)
{
    string schemaJson = WidgetSpecTranslator.DescriptorToSchemaJson(desc);
    ValidationResult validation = WidgetSchemaValidator.ValidateWidgetTree(schemaJson);
    Console.WriteLine($"{desc.Type}: {(validation.IsValid ? "valid" : "invalid")}");
}
```

Source spec files live in `tests/Fixtures/component_spec_*.json`.
Runtime integration: pass the resulting `WidgetNodeDescriptor` tree to your Godot node factory.

---

## Component name → widget type mapping

| Source name   | Widget type    | Status  |
|---------------|----------------|---------|
| Button        | button         | MAPPED  |
| Switch        | toggle         | MAPPED  |
| Toggle        | toggle         | MAPPED  |
| Slider        | slider         | MAPPED  |
| Label         | label          | MAPPED  |
| Text          | label          | MAPPED  |
| ListItem      | list_item      | MAPPED  |
| List_Item     | list_item      | MAPPED  |
| Row           | row            | MAPPED  |
| Column        | column         | MAPPED  |
| Stack         | stack          | MAPPED  |
| Grid          | grid           | MAPPED  |
| Panel         | widget_panel   | MAPPED  |
| DatePicker    | —              | NO MAP — warning emitted, component skipped |
| Checkbox      | —              | NO MAP — warning emitted, component skipped |
| Tabs          | —              | NO MAP — warning emitted, component skipped |
| Modal         | —              | NO MAP — warning emitted, component skipped |

---

## Prop mapping

| Source prop       | Widget schema field      | Status  | Notes |
|-------------------|--------------------------|---------|-------|
| label / text      | text                     | MAPPED  | String default extracted from prop descriptor |
| disabled          | enabled (inverted)       | MAPPED  | `disabled: true` → `enabled: false` |
| checked / value   | value (float)            | MAPPED  | bool coerced to 1.0 / 0.0 |
| width_dp          | size[0]                  | MAPPED  | × DpToMeters (0.001 m/dp) |
| height_dp         | size[1]                  | MAPPED  | × DpToMeters (0.001 m/dp) |
| width (unit=dp)   | size[0]                  | MAPPED  | unit field detected |
| height (unit=dp)  | size[1]                  | MAPPED  | unit field detected |
| min / max         | —                        | PARTIAL — warning emitted; no schema v1 field |
| variant           | —                        | UNSUPPORTED — warning emitted |
| color             | —                        | UNSUPPORTED — warning emitted |
| icon              | —                        | UNSUPPORTED — warning emitted |
| ripple            | —                        | UNSUPPORTED — warning emitted |
| elevation         | —                        | UNSUPPORTED — warning emitted |
| shape             | —                        | UNSUPPORTED — warning emitted |
| density           | —                        | UNSUPPORTED — warning emitted |
| tone              | —                        | UNSUPPORTED — warning emitted |
| corner_radius     | —                        | UNSUPPORTED — warning emitted |

---

## Events

Events have no equivalent in widget schema v1. Any `events` array in the spec produces a warning and is ignored. Event binding is planned for a future schema version.

## States

States are expressed through theme tokens (via `WidgetThemeData3D`) rather than as schema fields. Any `states` array in the spec produces a warning and is ignored.

---

## Translated component families

### inputs (component_spec_inputs.json)

| Component | Widget type | Size (m)      | value | enabled |
|-----------|-------------|---------------|-------|---------|
| Button    | button      | 0.088 × 0.040 | —     | true    |
| Switch    | toggle      | 0.052 × 0.032 | 0.0   | true    |
| Slider    | slider      | 0.200 × 0.040 | 0.0   | true    |

All three produce schema JSON that passes `WidgetSchemaValidator.ValidateWidgetTree`.

### display (component_spec_display.json)

| Component | Widget type | Size (m)      | value | enabled |
|-----------|-------------|---------------|-------|---------|
| Label     | label       | 0.160 × 0.032 | —     | true    |
| ListItem  | list_item   | 0.280 × 0.048 | —     | true    |

Both produce schema JSON that passes `WidgetSchemaValidator.ValidateWidgetTree`.

---

## Known gaps

1. **No event bindings** — schema v1 has no event field; translator cannot express click/change handlers.
2. **No min/max on sliders** — schema v1 assumes 0–1 normalised range; raw min/max values are dropped with a warning.
3. **No compound/composite components** — DatePicker, Tabs, Modal, Checkbox have no single-widget mapping; multi-widget expansion is out of scope for v1.
4. **No style props** — variant, color, icon, ripple, elevation, shape, density, tone, corner_radius all require theme token work (#62) before they can map.
5. **No nested children from spec** — translator produces flat per-component descriptors; layout composition into a widget tree must be done by the caller.
