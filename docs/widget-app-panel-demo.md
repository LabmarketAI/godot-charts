# Widget App-Style Panel Demo

Scene: `demo/scenes/app_panel_demo.tscn`
Controller: `demo/scenes/AppPanelDemo.cs`

Demonstrates a multi-step interaction flow assembled from MVP widgets — fulfilling issue #61.

## What it shows

| Feature | How |
|---|---|
| Exclusive list selection | Four chart-type list items; selecting one deselects the rest |
| State-driven UI | Apply button stays disabled until a chart type is chosen |
| Live data binding | Opacity slider updates a label in real-time |
| Multi-step flow | Select → Configure → Apply → Confirm/Cancel |
| Confirmation overlay | A second `WidgetPanel3D` slides in front of the main panel at runtime |
| Focus traversal | Tab/Shift-Tab moves through all controls in document order |

## Interaction flow

1. **Select** a chart type from the list (Bar, Line, Point, or Scatter).
2. **Adjust** Show Grid, Show Legend toggles and the Opacity slider.
3. Click **Apply** — a confirmation prompt appears naming the selected chart.
4. Click **Confirm** to commit (prints to the Godot output log) or **Cancel** to dismiss.
5. Click **Reset** at any time to restore the panel to its initial state.

## Desktop controls

- **Mouse** — hover and click any control; the cursor changes on hover.
- **Tab / Shift-Tab** — cycle keyboard focus through all interactive controls.
- **Enter / Space** — activate the focused button or toggle.

## XR controls

- Point the XR ray at a control and pull the trigger to interact.
- Focus follows the XR pointer; keyboard shortcuts are still available via the virtual keyboard.

## Scene structure

```
AppPanelDemo (Node3D)           ← AppPanelDemo.cs controller
  Frame (ChartFrame3D 3.6×2.6)
    Title (Label3D)             "[12] App-Style Panel"
    MainPanel (WidgetPanel3D)   ← main content, 3.4×2.4 m
      ContentColumn (WidgetColumn3D)
        LabelTitle              "Chart Configuration"
        LabelStep1              "1. Select chart type"
        ItemBar / ItemLine / ItemPoint / ItemScatter   (WidgetListItem3D)
        LabelStep2              "2. Configure"
        ToggleGrid              "Show Grid"
        ToggleLegend            "Show Legend"
        OpacityLabel            "Opacity: 1.0"  (live update)
        SliderOpacity           0.1 – 1.0
        ActionRow (WidgetRow3D)
          BtnApply              disabled until selection
          BtnReset
    ConfirmPanel (WidgetPanel3D) ← overlay, 2.4×0.55 m, hidden until Apply
      ConfirmColumn (WidgetColumn3D)
        LabelPrompt             "Apply '<chart>' settings?"
        ConfirmRow (WidgetRow3D)
          BtnConfirm
          BtnCancel
```
