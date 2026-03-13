// Standalone HistogramChart3D demo.
using Godot;

public partial class Histogram : Node3D
{
    public override void _Ready()
    {
        SetupEnv();

        var frame = new GodotCharts.ChartFrame3D { Size = new Vector2(6f, 4f) };
        AddChild(frame);

        var chart = new GodotCharts.HistogramChart3D
        {
            Title  = "Height Distribution (cm)",
            XLabel = "Height",
            YLabel = "Count",
            // Approximately normal distribution around 170 cm.
            RawData = new double[]
            {
                152.0, 155.0, 157.0, 158.0, 160.0, 161.0, 162.0, 163.0,
                163.0, 164.0, 165.0, 165.0, 166.0, 167.0, 167.0, 168.0,
                168.0, 169.0, 169.0, 170.0, 170.0, 170.0, 171.0, 171.0,
                172.0, 172.0, 173.0, 173.0, 174.0, 175.0, 176.0, 177.0,
                178.0, 180.0, 182.0, 185.0, 188.0,
            },
            NBins = 10,
        };
        frame.AddChild(chart);

        var cam = new Camera3D();
        AddChild(cam);
        cam.Position = new Vector3(3f, 2f, 10f);
        cam.LookAt(new Vector3(3f, 2f, 0f));
    }

    private void SetupEnv()
    {
        var env = new Godot.Environment
        {
            BackgroundMode     = Godot.Environment.BGMode.Color,
            BackgroundColor    = new Color(0.1f, 0.1f, 0.12f),
            AmbientLightSource = Godot.Environment.AmbientSource.Color,
            AmbientLightColor  = new Color(0.9f, 0.9f, 1f),
            AmbientLightEnergy = 0.7f,
        };
        AddChild(new WorldEnvironment { Environment = env });
        AddChild(new DirectionalLight3D { RotationDegrees = new Vector3(-45f, 30f, 0f) });
    }
}
