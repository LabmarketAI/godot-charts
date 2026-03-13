// Standalone ScatterChart3D demo.
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;

public partial class ScatterChart : Node3D
{
    public override void _Ready()
    {
        SetupEnv();

        var frame = new GodotCharts.ChartFrame3D { Size = new Vector2(6f, 4f) };
        AddChild(frame);

        var chart = new GodotCharts.ScatterChart3D
        {
            Title = "3-D Point Cloud",
            Data  = new Dictionary
            {
                ["datasets"] = new GDArray
                {
                    new Dictionary
                    {
                        ["name"]   = "Cluster A",
                        ["points"] = new GDArray
                        {
                            new Vector3(0.2f, 1.3f, 0.5f), new Vector3(0.8f, 0.4f, 1.1f),
                            new Vector3(0.5f, 0.9f, 0.7f), new Vector3(1.0f, 1.5f, 0.3f),
                            new Vector3(0.3f, 1.1f, 0.9f), new Vector3(0.7f, 0.6f, 1.3f),
                        },
                    },
                    new Dictionary
                    {
                        ["name"]   = "Cluster B",
                        ["points"] = new GDArray
                        {
                            new Vector3(2.0f, 0.6f, 0.3f), new Vector3(1.7f, 1.2f, 1.9f),
                            new Vector3(1.4f, 0.3f, 1.5f), new Vector3(1.9f, 1.8f, 0.8f),
                            new Vector3(2.2f, 1.0f, 1.2f), new Vector3(1.6f, 0.7f, 0.6f),
                        },
                    },
                    new Dictionary
                    {
                        ["name"]   = "Cluster C",
                        ["points"] = new GDArray
                        {
                            new Vector3(1.0f, 2.5f, 1.5f), new Vector3(1.2f, 2.2f, 1.8f),
                            new Vector3(0.8f, 2.8f, 1.2f), new Vector3(1.4f, 2.4f, 1.0f),
                        },
                    },
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
