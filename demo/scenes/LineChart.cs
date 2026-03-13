// Standalone LineChart3D demo.
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;

public partial class LineChart : Node3D
{
    public override void _Ready()
    {
        SetupEnv();

        var frame = new GodotCharts.ChartFrame3D { Size = new Vector2(6f, 4f) };
        AddChild(frame);

        var chart = new GodotCharts.LineChart3D
        {
            Title  = "Stock Prices",
            XLabel = "Week",
            YLabel = "USD",
            Data   = new Dictionary
            {
                ["labels"]   = new GDArray { "Wk1", "Wk2", "Wk3", "Wk4", "Wk5", "Wk6" },
                ["datasets"] = new GDArray
                {
                    new Dictionary { ["name"] = "ACME",  ["values"] = new GDArray { 142.0, 138.0, 155.0, 149.0, 162.0, 171.0 } },
                    new Dictionary { ["name"] = "Globex", ["values"] = new GDArray {  98.0, 105.0, 101.0, 112.0, 108.0, 120.0 } },
                },
            },
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
