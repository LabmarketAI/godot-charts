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
using System;
using Godot;

public partial class Main : Node3D
{
    private const string ToggleConsoleAction = "toggle_diegetic_console";
    private const bool DefaultConsoleVisible = false;
    private const string HeadlessSmokeEnvVar = "GODOT_CHARTS_SMOKE";
    private const string HeadlessSmokeProjectSetting = "labmarket/testing_enable_headless_smoke";
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
    private DataBindingService _bindingService = null!;
    private MessageBusService _messageBusService = null!;
    private DemoDataGenerator _demoDataGenerator = null!;
    private ConsoleRoot _consoleRoot = null!;

    public override void _Ready()
    {
        ConfigureXrViewport();
        _player = GetNode<FpsPlayer>("FPSPlayer");
        EnsureConsoleAction();
        SetupWorkspaceAndConsole();
        ShowHint();
        CallDeferred(MethodName.SetupDesktopCapture);
    }

    private void ConfigureXrViewport()
    {
        var xrInterface = XRServer.PrimaryInterface;
        if (xrInterface == null || !xrInterface.IsInitialized())
            return;

        var viewport = GetViewport();
        if (!viewport.UseXR)
            viewport.UseXR = true;
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

        _bindingService = new DataBindingService { Name = "DataBindingService" };
        AddChild(_bindingService);
        _bindingService.Initialize(_frameService, _workspaceService, GetNode<Node3D>("DataRoom"));

        _messageBusService = new MessageBusService { Name = "MessageBusService" };
        AddChild(_messageBusService);
        _bindingService.BindMessageBus(_messageBusService);

        _demoDataGenerator = new DemoDataGenerator { Name = "DemoDataGenerator" };
        AddChild(_demoDataGenerator);
        _demoDataGenerator.Initialize(_messageBusService);

        var packed = GD.Load<PackedScene>("res://scenes/console_root.tscn");
        _consoleRoot = packed.Instantiate<ConsoleRoot>();
        _consoleRoot.Name = "ConsoleRoot";
        _consoleRoot.Position = ConsoleSpawnPosition;
        AddChild(_consoleRoot);
        _consoleRoot.BindWorkspaceService(_workspaceService);
        _consoleRoot.BindFrameService(_frameService);
        _consoleRoot.BindBindingService(_bindingService);
        _consoleRoot.BindMessageBus(_messageBusService);

        MaybeEnableHeadlessSmokeHarness();

        if (_workspaceService.ActiveWorkspaceProfile.TryGetValue("console_visible", out var storedVisible))
            _consoleRoot.SetConsoleVisible(storedVisible.AsBool());
        else
            _consoleRoot.SetConsoleVisible(DefaultConsoleVisible);
    }

    private void MaybeEnableHeadlessSmokeHarness()
    {
        var envEnabled = string.Equals(System.Environment.GetEnvironmentVariable(HeadlessSmokeEnvVar), "1", StringComparison.Ordinal);
        var projectEnabled = ProjectSettings.HasSetting(HeadlessSmokeProjectSetting)
            && ProjectSettings.GetSetting(HeadlessSmokeProjectSetting).AsBool();

        if (!envEnabled && !projectEnabled)
            return;

        CallDeferred(MethodName.ConfigureHeadlessSmokeFrames);
    }

    private void ConfigureHeadlessSmokeFrames()
    {
        if (_frameService == null || _bindingService == null || _messageBusService == null)
            return;

        var chartTypes = new[] { "bar", "line", "scatter", "surface", "histogram", "network" };
        foreach (var chartType in chartTypes)
        {
            var frameId = _frameService.CreateFrameAndReturnId(chartType, "compact");
            if (string.IsNullOrWhiteSpace(frameId))
            {
                GD.Print($"SmokeHarnessFrameCreateFailed: chart_type={chartType}");
                continue;
            }

            GD.Print($"SmokeHarnessFrameCreated: chart_type={chartType} frame_id={frameId}");
            _bindingService.SetBindingKind(frameId, "demo_stream", persist: false);
        }

        EnsureSmokeHistogramBinding();
        LogSmokeTopicSubscribers();

        // Force an immediate publish cycle via running-state transition.
        _messageBusService.Stop();
        _messageBusService.Start();
        GD.Print("SmokeHarnessConfigured: runtime demo_stream frames created for bar/line/scatter/surface/histogram/network");
    }

    private void EnsureSmokeHistogramBinding()
    {
        if (_frameService == null || _bindingService == null)
            return;

        string histogramFrameId = string.Empty;
        foreach (var profile in _frameService.ListRuntimeFrameProfiles())
        {
            if (!profile.TryGetValue("id", out var idVariant))
                continue;

            var frameId = idVariant.AsString();
            if (string.IsNullOrWhiteSpace(frameId))
                continue;

            if (_frameService.GetFrameChartType(frameId) != "histogram")
                continue;

            histogramFrameId = frameId;
            break;
        }

        if (string.IsNullOrWhiteSpace(histogramFrameId))
        {
            histogramFrameId = _frameService.CreateFrameAndReturnId("histogram", "compact");
            if (!string.IsNullOrWhiteSpace(histogramFrameId))
                GD.Print($"SmokeHarnessHistogramCreated: frame_id={histogramFrameId}");
        }

        if (string.IsNullOrWhiteSpace(histogramFrameId))
            return;

        _bindingService.SetBindingKind(histogramFrameId, "demo_stream", persist: false);
        GD.Print($"SmokeHarnessHistogramBound: frame_id={histogramFrameId}");
    }

    private void LogSmokeTopicSubscribers()
    {
        if (_messageBusService == null)
            return;

        var topics = new[]
        {
            "demo/stream/bar",
            "demo/stream/line",
            "demo/stream/scatter",
            "demo/stream/histogram",
            "demo/stream/surface",
            "demo/stream/graph_network",
        };

        foreach (var topic in topics)
        {
            var subscribers = _messageBusService.GetSubscriberCount(topic);
            GD.Print($"SmokeHarnessSubscribers: topic={topic} subscribers={subscribers}");
        }
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
