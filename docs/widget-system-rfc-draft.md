# Widget System RFC Draft (Phase 0)

Parent epic: #56

Related child issue: #57

## Purpose

Capture initial architecture decisions for a Godot-native 3D/VR widget system:

1. Declarative widget schema.
2. Tokenized theme model.
3. Unified desktop/XR focus and input policy.

This document is a kickoff draft to start Phase 0 and is expected to evolve.

## Early Architecture Decisions

1. Rendering model
   - Widgets render natively in Godot (no DOM/CSS runtime emulation).
   - World-space UI hosts use `WidgetPanel3D` as the anchoring container.
2. Data model
   - Widget trees are declarative JSON-like objects.
   - Themes are token dictionaries with semantic keys.
3. Interaction model
   - One focus manager mediates keyboard, pointer, and XR-ray focus ownership.

## Draft Widget Schema (v0)

```json
{
  "schemaVersion": "0.1.0",
  "root": {
    "id": "settings_panel",
    "type": "column",
    "props": {
      "gap": "space.3",
      "padding": "space.4"
    },
    "children": [
      {
        "id": "title",
        "type": "text",
        "props": {
          "value": "Widget Demo",
          "variant": "heading.md"
        }
      },
      {
        "id": "enable_toggle",
        "type": "toggle",
        "props": {
          "label": "Enable live updates",
          "value": true
        },
        "events": {
          "onChange": "settings.toggleLiveUpdates"
        }
      },
      {
        "id": "save_button",
        "type": "button",
        "props": {
          "label": "Save",
          "variant": "primary"
        },
        "events": {
          "onPress": "settings.save"
        }
      }
    ]
  }
}
```

## Draft Theme Tokens (v0)

```json
{
  "themeVersion": "0.1.0",
  "meta": {
    "name": "neutral-default"
  },
  "color": {
    "surface.base": "#11161D",
    "surface.elevated": "#1A2230",
    "text.primary": "#E8EEF8",
    "text.muted": "#A8B5CC",
    "action.primary": "#3A86FF",
    "action.primaryHover": "#5C9CFF",
    "focus.ring": "#F4D35E"
  },
  "space": {
    "1": 4,
    "2": 8,
    "3": 12,
    "4": 16,
    "5": 24
  },
  "radius": {
    "sm": 4,
    "md": 8,
    "lg": 12
  },
  "type": {
    "heading.md": {
      "size": 24,
      "weight": 700
    },
    "body.md": {
      "size": 16,
      "weight": 400
    }
  },
  "motion": {
    "duration.fast": 120,
    "duration.normal": 180,
    "easing.standard": "ease_out_cubic"
  }
}
```

## Focus and Input Policy (Draft)

1. Focus owner precedence
   - Explicit user interaction wins (latest pointer or keyboard action becomes owner).
   - XR ray hover alone does not steal keyboard focus unless activation occurs.
2. Activation behavior
   - Keyboard activation: Enter/Space triggers focused actionable control.
   - Pointer/XR activation: press trigger/click triggers target and updates focus.
3. Escape hatches
   - `Esc` closes top-most modal and restores previous focus anchor.
   - If a focused control is removed, focus falls back to nearest enabled ancestor/sibling.

## Open Questions

1. Should list virtualization be required in MVP or deferred to Phase 3?
2. How should form validation messages be represented in schema (`errors` field vs event callbacks)?
3. Should theme token units be raw numbers only, or allow named aliases in all fields?
4. What minimum XR target size should be enforced by default?

## Immediate Next Steps

1. Iterate this draft under issue #57 review comments.
2. Start concrete `WidgetPanel3D` + layout implementation under #58.
3. Keep issue #56 checklist synced as child issues move forward.
