// Graph network demo — shows GraphNetworkChart3D.
// Press [Tab] to cycle through layout modes (Preset → Circular → Spring → Hierarchical).
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;
using GDDict  = Godot.Collections.Dictionary;

public partial class GraphNetwork : Node3D
{
    private Node3D? _chart;
    private int _layout = 1; // start at Circular

    private static readonly GDDict GraphData = new GDDict
    {
        ["nodes"] = new GDArray
        {
            new GDDict { ["id"] = "alice",  ["label"] = "Alice",  ["type"] = "person"  },
            new GDDict { ["id"] = "bob",    ["label"] = "Bob",    ["type"] = "person"  },
            new GDDict { ["id"] = "carol",  ["label"] = "Carol",  ["type"] = "person"  },
            new GDDict { ["id"] = "dave",   ["label"] = "Dave",   ["type"] = "person"  },
            new GDDict { ["id"] = "server", ["label"] = "Server", ["type"] = "machine" },
            new GDDict { ["id"] = "db",     ["label"] = "DB",     ["type"] = "machine" },
        },
        ["edges"] = new GDArray
        {
            new GDDict { ["source"] = "alice",  ["target"] = "bob",    ["label"] = "friend"   },
            new GDDict { ["source"] = "alice",  ["target"] = "carol",  ["label"] = "friend"   },
            new GDDict { ["source"] = "bob",    ["target"] = "server", ["label"] = "connects" },
            new GDDict { ["source"] = "carol",  ["target"] = "server", ["label"] = "connects" },
            new GDDict { ["source"] = "dave",   ["target"] = "server", ["label"] = "connects" },
            new GDDict { ["source"] = "server", ["target"] = "db",     ["label"] = "reads"    },
        },
    };

    public override void _Ready()
    {
        SetupEnv();

        var frame = new GodotCharts.ChartFrame3D
        {
            Size     = new Vector2(6f, 5f),
            Position = new Vector3(0f, 0f, 0f),
        };
        AddChild(frame);

        var chart = new GodotCharts.GraphNetworkChart3D
        {
            Title      = "Graph Network 3D",
            Layout     = (GodotCharts.GraphNetworkChart3D.LayoutMode)_layout,
            Data       = GraphData,
        };
        _chart = chart;
        frame.AddChild(chart);

        var cam = new Camera3D();
        AddChild(cam);
        cam.Position = new Vector3(3f, 2.5f, 14f);
        cam.LookAt(new Vector3(3f, 2.5f, 0f));

        var hint = new Label3D
        {
            Text      = "Press [Tab] to cycle layout modes",
            FontSize  = 18,
            Billboard = BaseMaterial3D.BillboardModeEnum.Enabled,
            Position  = new Vector3(3f, -0.8f, 0f),
        };
        AddChild(hint);
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventKey key && key.Keycode == Key.Tab && key.Pressed)
        {
            _layout = (_layout + 1) % 4;
            if (_chart is GodotCharts.GraphNetworkChart3D c)
                c.Layout = (GodotCharts.GraphNetworkChart3D.LayoutMode)_layout;
        }
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
        var sun = new DirectionalLight3D { RotationDegrees = new Vector3(-45f, 30f, 0f) };
        AddChild(sun);
    }
}
