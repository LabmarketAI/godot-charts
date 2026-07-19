// Standalone BarChart3D demo.
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;

public partial class BarChart : Node3D
{
    public override void _Ready()
    {
        SetupEnv();

        var frame = new GodotCharts.ChartFrame3D { Size = new Vector2(6f, 4f) };
        AddChild(frame);

        var chart = new GodotCharts.BarChart3D
        {
            Title  = "Monthly Sales",
            XLabel = "Month",
            YLabel = "Units",
            Data   = new Dictionary
            {
                ["labels"]   = new GDArray { "Jan", "Feb", "Mar", "Apr", "May", "Jun" },
                ["datasets"] = new GDArray
                {
                    new Dictionary { ["name"] = "Product A", ["values"] = new GDArray { 120.0, 95.0, 140.0, 180.0, 160.0, 210.0 } },
                    new Dictionary { ["name"] = "Product B", ["values"] = new GDArray {  80.0, 110.0, 90.0, 130.0, 100.0, 145.0 } },
                    new Dictionary { ["name"] = "Product C", ["values"] = new GDArray {  60.0,  70.0, 80.0,  75.0,  90.0,  95.0 } },
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
            BackgroundMode      = Godot.Environment.BGMode.Color,
            BackgroundColor     = new Color(0.1f, 0.1f, 0.12f),
            AmbientLightSource  = Godot.Environment.AmbientSource.Color,
            AmbientLightColor   = new Color(0.9f, 0.9f, 1f),
            AmbientLightEnergy  = 0.7f,
        };
        AddChild(new WorldEnvironment { Environment = env });
        AddChild(new DirectionalLight3D { RotationDegrees = new Vector3(-45f, 30f, 0f) });
    }
}
