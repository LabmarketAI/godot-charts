// Standalone SurfaceChart3D demo.
// Press Space to toggle between function and grid-data modes.
using System;
using Godot;
using GDArray = Godot.Collections.Array;

public partial class SurfaceChart : Node3D
{
    private Node3D? _chart;
    private int _mode;

    public override void _Ready()
    {
        SetupEnv();

        var frame = new GodotCharts.ChartFrame3D { Size = new Vector2(6f, 4f) };
        AddChild(frame);

        var chart = new GodotCharts.SurfaceChart3D { GridCols = 28, GridRows = 28 };
        _chart = chart;
        frame.AddChild(chart);
        ApplyMode();

        var cam = new Camera3D();
        AddChild(cam);
        cam.Position = new Vector3(3f, 2f, 10f);
        cam.LookAt(new Vector3(3f, 2f, 0f));

        var hint = new Label3D
        {
            Text      = "Press [Space] to switch surface mode",
            FontSize  = 18,
            Billboard = BaseMaterial3D.BillboardModeEnum.Enabled,
            Position  = new Vector3(3f, -0.6f, 0f),
        };
        AddChild(hint);
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventKey key && key.Keycode == Key.Space && key.Pressed)
        {
            _mode = (_mode + 1) % 2;
            ApplyMode();
        }
    }

    private void ApplyMode()
    {
        if (_chart is not GodotCharts.SurfaceChart3D c) return;
        if (_mode == 0)
        {
            c.Title           = "sin(x)·cos(z)  [function]";
            c.SurfaceFunction = (x, z) =>
                MathF.Sin(x * MathF.Tau) * MathF.Cos(z * MathF.Tau) * 0.5f + 0.5f;
        }
        else
        {
            c.Title           = "Grid data";
            c.SurfaceFunction = null;
            c.GridData        = BuildGridData(new double[][]
            {
                new[] { 0.0, 0.2, 0.5, 0.8, 1.0 },
                new[] { 0.1, 0.4, 0.9, 0.6, 0.7 },
                new[] { 0.3, 0.7, 1.5, 0.8, 0.4 },
                new[] { 0.5, 0.9, 0.8, 0.5, 0.2 },
                new[] { 0.2, 0.4, 0.3, 0.1, 0.0 },
            });
        }
    }

    private static GDArray BuildGridData(double[][] rows)
    {
        var grid = new GDArray();
        foreach (var rowData in rows)
        {
            var row = new GDArray();
            foreach (double v in rowData)
                row.Add(Variant.From(v));
            grid.Add(Variant.From(row));
        }
        return grid;
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
