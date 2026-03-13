using System.Collections.Generic;
using Godot;

public partial class CircuitChart : Node3D
{
    private GodotCharts.CircuitChart3D? _chart;
    private int _layer = -1;

    public override void _Ready()
    {
        SetupEnv();

        var frame = new GodotCharts.ChartFrame3D
        {
            Size = new Vector2(6f, 5f),
        };
        AddChild(frame);

        var chart = new GodotCharts.CircuitChart3D
        {
            Position = new Vector3(0.15f, 0.15f, 0.005f),
            ChartSize = new Vector2(5.7f, 4.7f),
            Title = "Layered Circuit Sample",
            Circuit = BuildSampleCircuit(),
        };
        _chart = chart;
        frame.AddChild(chart);

        var cam = new Camera3D();
        AddChild(cam);
        cam.Position = new Vector3(3f, 2.4f, 10f);
        cam.LookAt(new Vector3(3f, 2.2f, 0f));

        var hint = new Label3D
        {
            Text = "Press [Tab] to scrub layers",
            FontSize = 18,
            Billboard = BaseMaterial3D.BillboardModeEnum.Enabled,
            Position = new Vector3(3f, -0.75f, 0f),
        };
        AddChild(hint);
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is not InputEventKey key || !key.Pressed || key.Keycode != Key.Tab)
            return;

        if (_chart?.Circuit == null)
            return;

        int maxLayer = _chart.Circuit.Layers.Count - 1;
        _layer = _layer >= maxLayer ? -1 : _layer + 1;
        _chart.ShowLayer(_layer);
    }

    private static GodotCharts.CircuitGraph BuildSampleCircuit()
    {
        var allOps = new List<GodotCharts.QuantumOp>
        {
            new("h0", "h", new[] { 0 }, System.Array.Empty<int>(), System.Array.Empty<float>(), 0),
            new("x1", "x", new[] { 1 }, System.Array.Empty<int>(), System.Array.Empty<float>(), 0),
            new("cx01", "cx", new[] { 0, 1 }, System.Array.Empty<int>(), System.Array.Empty<float>(), 1),
            new("rz1", "rz", new[] { 1 }, System.Array.Empty<int>(), new[] { 1.5708f }, 2),
            new("cz12", "cz", new[] { 1, 2 }, System.Array.Empty<int>(), System.Array.Empty<float>(), 3),
            new("h2", "h", new[] { 2 }, System.Array.Empty<int>(), System.Array.Empty<float>(), 4),
        };

        var layers = new List<GodotCharts.QuantumLayer>
        {
            new(0, new[] { allOps[0], allOps[1] }),
            new(1, new[] { allOps[2] }),
            new(2, new[] { allOps[3] }),
            new(3, new[] { allOps[4] }),
            new(4, new[] { allOps[5] }),
        };

        return new GodotCharts.CircuitGraph(3, layers, allOps);
    }

    private void SetupEnv()
    {
        var env = new Godot.Environment
        {
            BackgroundMode = Godot.Environment.BGMode.Color,
            BackgroundColor = new Color(0.1f, 0.1f, 0.12f),
            AmbientLightSource = Godot.Environment.AmbientSource.Color,
            AmbientLightColor = new Color(0.9f, 0.9f, 1f),
            AmbientLightEnergy = 0.7f,
        };

        AddChild(new WorldEnvironment { Environment = env });
        AddChild(new DirectionalLight3D { RotationDegrees = new Vector3(-45f, 30f, 0f) });
    }
}
