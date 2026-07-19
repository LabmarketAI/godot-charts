using Godot;

/// <summary>
/// Demo scene controller for the theme engine.
/// Wires the "Neutral" and "High Contrast" buttons to WidgetThemeManager
/// so players can toggle themes at runtime without a scene reload.
/// </summary>
public partial class WidgetThemeDemo : Node3D
{
    public override void _Ready()
    {
        var btnNeutral = GetNodeOrNull<Area3D>("Frame/Panel/ContentColumn/ButtonRow/BtnNeutral");
        var btnHighContrast = GetNodeOrNull<Area3D>("Frame/Panel/ContentColumn/ButtonRow/BtnHighContrast");

        if (btnNeutral != null)
            btnNeutral.Connect("pressed", Callable.From(() => SetPreset("neutral")));

        if (btnHighContrast != null)
            btnHighContrast.Connect("pressed", Callable.From(() => SetPreset("high_contrast")));
    }

    static void SetPreset(string name)
    {
        var mgr = (Engine.GetMainLoop() as SceneTree)?.Root?.GetNodeOrNull("/root/WidgetThemeManager");
        if (mgr == null)
        {
            GD.PrintErr("WidgetThemeDemo: WidgetThemeManager autoload not found.");
            return;
        }
        mgr.Call("set_preset", name);
    }
}
