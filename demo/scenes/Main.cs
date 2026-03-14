// Godot Charts — desktop demo.
//
// Seven chart frames are arranged at octagon positions around a central room.
// Walk with WASD, look with the mouse.  Press [1]–[7] to instantly teleport
// to the viewing position in front of each chart.
// Press [Escape] to release / recapture the mouse cursor.
//
// Layout (top view, 7 of 8 octagon vertices, clockwise from +Z):
//   slot 0  (  0°) BarChart3D        slot 1  ( 45°) LineChart3D
//   slot 2  ( 90°) ScatterChart3D    slot 3  (135°) SurfaceChart3D
//   slot 4  (180°) HistogramChart3D  slot 5  (225°) GraphNetworkChart3D
//   slot 6  (270°) CircuitChart3D    [315° is DesktopPanel]
using Godot;

public partial class Main : Node3D
{
    private const string ToggleConsoleAction = "toggle_diegetic_console";
    private const bool DefaultConsoleVisible = false;
    private static readonly Vector3 ConsoleSpawnPosition = new(0f, 1.65f, -2.35f);

    private const float FrameH        = 4f;
    private const float OctagonRadius = 7.5f;
    private const float CameraInset   = 4.5f;

    // Precomputed octagon anchor positions and Y-rotation angles for all 7 chart slots.
    private static readonly Vector3[] SlotAnchors =
    {
        new Vector3( 0f,       1f,  7.5f),       // slot 0  (  0°)
        new Vector3( 5.303301f, 1f,  5.303301f),  // slot 1  ( 45°)
        new Vector3( 7.5f,     1f,  0f),          // slot 2  ( 90°)
        new Vector3( 5.303301f, 1f, -5.303301f),  // slot 3  (135°)
        new Vector3( 0f,       1f, -7.5f),        // slot 4  (180°)
        new Vector3(-5.303301f, 1f, -5.303301f),  // slot 5  (225°)
        new Vector3(-7.5f,     1f,  0f),          // slot 6  (270°)
    };

    private static readonly float[] SlotAngles =
    {
        0f,
        Mathf.Pi / 4f,
        Mathf.Pi / 2f,
        3f * Mathf.Pi / 4f,
        Mathf.Pi,
        5f * Mathf.Pi / 4f,
        3f * Mathf.Pi / 2f,
    };

    private FpsPlayer _player = null!;
    private WorkspaceStateService _workspaceService = null!;
    private FrameOrchestrationService _frameService = null!;
    private ConsoleRoot _consoleRoot = null!;

    public override void _Ready()
    {
        _player = GetNode<FpsPlayer>("FPSPlayer");
        EnsureConsoleAction();
        SetupWorkspaceAndConsole();
        ShowHint();
        CallDeferred(MethodName.SetupDesktopCapture);
    }

    private void EnsureConsoleAction()
    {
        if (!InputMap.HasAction(ToggleConsoleAction))
            InputMap.AddAction(ToggleConsoleAction);

        foreach (InputEvent ev in InputMap.ActionGetEvents(ToggleConsoleAction))
        {
            if (ev is InputEventKey key && key.Keycode == Key.F1)
                return;
        }

        var keyEvent = new InputEventKey
        {
            Keycode = Key.F1,
            PhysicalKeycode = Key.F1,
        };
        InputMap.ActionAddEvent(ToggleConsoleAction, keyEvent);
    }

    private void SetupWorkspaceAndConsole()
    {
        _workspaceService = new WorkspaceStateService { Name = "WorkspaceStateService" };
        AddChild(_workspaceService);

        _frameService = new FrameOrchestrationService { Name = "FrameOrchestrationService" };
        AddChild(_frameService);
        _frameService.Initialize(GetNode<Node3D>("DataRoom"), _workspaceService);

        var packed = GD.Load<PackedScene>("res://scenes/console_root.tscn");
        _consoleRoot = packed.Instantiate<ConsoleRoot>();
        _consoleRoot.Name = "ConsoleRoot";
        _consoleRoot.Position = ConsoleSpawnPosition;
        AddChild(_consoleRoot);
        _consoleRoot.BindWorkspaceService(_workspaceService);
        _consoleRoot.BindFrameService(_frameService);

        if (_workspaceService.ActiveWorkspaceProfile.TryGetValue("console_visible", out var storedVisible))
            _consoleRoot.SetConsoleVisible(storedVisible.AsBool());
        else
            _consoleRoot.SetConsoleVisible(DefaultConsoleVisible);
    }

    private void SetupDesktopCapture()
    {
        var panel = GetNodeOrNull<MeshInstance3D>("DataRoom/DesktopPanel");
        if (panel == null) return;
        var mat = panel.GetSurfaceOverrideMaterial(0) as StandardMaterial3D;
        if (mat == null) return;
        var tex = mat.AlbedoTexture;
        if (tex == null || !tex.HasMethod("get_available_windows")) return;

        var windows = tex.Call("get_available_windows").AsGodotArray();
        GD.Print("Available windows for capture:");
        long targetId = 0;
        foreach (Variant w in windows)
        {
            var wDict = w.AsGodotDictionary();
            string title = wDict["title"].AsString();
            long id      = wDict["id"].AsInt64();
            GD.Print($" - {title} (ID: {id})");
            if (targetId == 0 && !string.IsNullOrWhiteSpace(title) && !title.Contains("Godot"))
                targetId = id;
        }

        if (targetId != 0)
        {
            tex.Set("window_id", targetId);
            GD.Print($"Auto-selected window ID: {targetId}");
        }
    }

    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed(ToggleConsoleAction))
        {
            _consoleRoot.ToggleConsole();
            _workspaceService.SaveActiveWorkspace(_consoleRoot.IsConsoleVisible);
            GetViewport().SetInputAsHandled();
            return;
        }

        if (@event is not InputEventKey key || !key.Pressed) return;
        int k = (int)key.Keycode;
        if (k >= (int)Key.Key1 && k <= (int)Key.Key7)
            FlyTo(k - (int)Key.Key1);
    }

    /// <summary>
    /// Teleport the player to the radial viewing position for chart <paramref name="idx"/>.
    /// The player stands 3 m in front of the chart frame and faces the chart centre.
    /// </summary>
    private void FlyTo(int idx)
    {
        float angle     = SlotAngles[idx];
        float camR      = OctagonRadius - CameraInset; // = 3.0 m
        var playerPos   = new Vector3(Mathf.Sin(angle) * camR, 0.9f, Mathf.Cos(angle) * camR);
        var anchor      = SlotAnchors[idx];
        var chartCentre = anchor + new Vector3(0f, FrameH * 0.5f, 0f);
        _player.TeleportTo(playerPos, chartCentre);
    }

    private static void ShowHint()
    {
        GD.Print("Godot Charts Demo — WASD to walk, mouse to look, [1]-[7] to jump to a chart, [Esc] to toggle mouse lock.");
    }
}
