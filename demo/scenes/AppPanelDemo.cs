using Godot;

/// <summary>
/// Controller for the app-style panel demo (issue #61).
///
/// Demonstrates a multi-step interaction flow using MVP widgets:
///   1. User selects a chart type from a list (exclusive selection).
///   2. User adjusts per-chart settings (toggles, slider).
///   3. User clicks Apply — a confirmation overlay appears.
///   4. User Confirms or Cancels.  Reset restores initial state.
///
/// The Apply button is disabled until a chart type is selected, demonstrating
/// state-driven UI.  The Opacity slider updates a live label, demonstrating
/// data binding.  Focus traverses all controls via Tab/Shift-Tab.
/// </summary>
public partial class AppPanelDemo : Node3D
{
    private static readonly (string NodeName, string Label)[] ChartItems =
    [
        ("ItemBar",     "Bar Chart"),
        ("ItemLine",    "Line Chart"),
        ("ItemPoint",   "Point Chart"),
        ("ItemScatter", "Scatter Chart"),
    ];

    private string  _selectedChart = "";
    private float   _opacityValue  = 1.0f;

    private Node3D  _confirmPanel  = null!;
    private Node    _opacityLabel  = null!;
    private Node    _confirmPrompt = null!;
    private Area3D  _btnApply      = null!;

    public override void _Ready()
    {
        _confirmPanel  = GetNode<Node3D>("Frame/ConfirmPanel");
        _confirmPanel.Visible = false;

        _opacityLabel  = GetNode("Frame/MainPanel/ContentColumn/OpacityLabel");
        _confirmPrompt = GetNode("Frame/ConfirmPanel/ConfirmColumn/LabelPrompt");
        _btnApply      = GetNode<Area3D>("Frame/MainPanel/ContentColumn/ActionRow/BtnApply");
        _btnApply.Set("enabled", false);

        foreach (var (nodeName, label) in ChartItems)
        {
            var capturedLabel = label;
            GetNode<Area3D>($"Frame/MainPanel/ContentColumn/{nodeName}")
                .Connect("selected", Callable.From<GodotObject>(_ => OnChartSelected(capturedLabel)));
        }

        GetNode<Area3D>("Frame/MainPanel/ContentColumn/SliderOpacity")
            .Connect("value_changed", Callable.From<float>(OnOpacityChanged));

        _btnApply
            .Connect("pressed", Callable.From(OnApplyPressed));

        GetNode<Area3D>("Frame/MainPanel/ContentColumn/ActionRow/BtnReset")
            .Connect("pressed", Callable.From(OnResetPressed));

        GetNode<Area3D>("Frame/ConfirmPanel/ConfirmColumn/ConfirmRow/BtnConfirm")
            .Connect("pressed", Callable.From(OnConfirmPressed));

        GetNode<Area3D>("Frame/ConfirmPanel/ConfirmColumn/ConfirmRow/BtnCancel")
            .Connect("pressed", Callable.From(OnCancelPressed));
    }

    private void OnChartSelected(string chartName)
    {
        _selectedChart = chartName;
        _btnApply.Set("enabled", true);

        foreach (var (nodeName, label) in ChartItems)
        {
            if (label != chartName)
                GetNode($"Frame/MainPanel/ContentColumn/{nodeName}").Set("selected_item", false);
        }
    }

    private void OnOpacityChanged(float value)
    {
        _opacityValue = value;
        _opacityLabel.Set("text", $"Opacity: {value:F1}");
    }

    private void OnApplyPressed()
    {
        if (string.IsNullOrEmpty(_selectedChart)) return;
        _confirmPrompt.Set("text", $"Apply '{_selectedChart}' settings?");
        _confirmPanel.Visible = true;
    }

    private void OnResetPressed()
    {
        _selectedChart = "";
        _btnApply.Set("enabled", false);

        foreach (var (nodeName, _) in ChartItems)
            GetNode($"Frame/MainPanel/ContentColumn/{nodeName}").Set("selected_item", false);

        GetNode("Frame/MainPanel/ContentColumn/SliderOpacity").Set("value", 1.0f);
        _opacityLabel.Set("text", "Opacity: 1.0");
    }

    private void OnConfirmPressed()
    {
        _confirmPanel.Visible = false;
        GD.Print($"AppPanelDemo: applied chart='{_selectedChart}' opacity={_opacityValue:F1}");
    }

    private void OnCancelPressed()
    {
        _confirmPanel.Visible = false;
    }
}
