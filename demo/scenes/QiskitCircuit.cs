using Godot;

public partial class QiskitCircuit : Node3D
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
            Title = "Qiskit Bell Circuit",
            CircuitFilePath = "res://data/circuit_bell_qiskit.json",
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
