using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;
using GodotCharts;
using GDArray = Godot.Collections.Array;
using GDDict = Godot.Collections.Dictionary;

public partial class DataBindingService : Node
{
[Signal]
public delegate void FrameBindingsChangedEventHandler();

private const string BindingsProfileKey = "bindings";
private const string FramePresetsProfileKey = "frame_presets";
private const string DesktopWindowsProfileKey = "desktop_windows";
private const string EnvironmentPresetProfileKey = "environment_preset";

private const string BindingStatic = "demo_static";
private const string BindingStream = "demo_stream";
private const double StreamTickSeconds = 0.45;

private static readonly string[] DaylightHdriCandidates =
{
"res://assets/hdri/daylight.hdr",
"res://assets/hdri/daylight.exr",
"res://assets/hdri/daylight.ktx",
};

private static readonly string[] StudioHdriCandidates =
{
"res://assets/hdri/studio.hdr",
"res://assets/hdri/studio.exr",
"res://assets/hdri/studio.ktx",
};

private static readonly string[] NightHdriCandidates =
{
"res://assets/hdri/night.hdr",
"res://assets/hdri/night.exr",
"res://assets/hdri/night.ktx",
};

private WorkspaceStateService? _workspaceService;
private FrameOrchestrationService? _frameService;
private Node3D? _dataRoom;
private Texture2D? _desktopPrototypeTexture;
private WorldEnvironment? _worldEnvironment;
private DirectionalLight3D? _directionalLight;
private SpotLight3D? _spotLightA;
private SpotLight3D? _spotLightB;

private readonly System.Collections.Generic.Dictionary<string, string> _bindingByFrame = new();
private readonly System.Collections.Generic.Dictionary<string, string> _framePresetByFrame = new();
private readonly System.Collections.Generic.Dictionary<string, long> _desktopWindowByFrame = new();
private readonly System.Collections.Generic.Dictionary<string, RuntimeBindingState> _stateByFrame = new();
private string _environmentPreset = "daylight";
private string _environmentStatus = "pending";
private bool _loggedMissingEnvironmentNodes;
private double _streamAccumulator;

public static readonly string[] SupportedBindingKinds =
{
BindingStatic,
BindingStream,
};

public static readonly string[] SupportedFramePresets =
{
"neutral",
"focus",
"presentation",
};

public static readonly string[] SupportedEnvironmentPresets =
{
"daylight",
"studio",
"night",
};

public void Initialize(FrameOrchestrationService frameService, WorkspaceStateService workspaceService, Node3D dataRoom)
{
_frameService = frameService;
_workspaceService = workspaceService;
_dataRoom = dataRoom;

ResolveDesktopPrototypeTexture();
ResolveEnvironmentNodes();

_workspaceService.WorkspaceLoaded += OnWorkspaceLoaded;
_frameService.RuntimeFramesChanged += OnRuntimeFramesChanged;
ApplyWorkspaceState();
}

public string GetEnvironmentPreset()
{
return _environmentPreset;
}

public string GetEnvironmentStatus()
{
return _environmentStatus;
}

public bool SetEnvironmentPreset(string environmentPreset, bool persist = true)
{
_environmentPreset = NormalizeEnvironmentPreset(environmentPreset);
ApplyEnvironmentPresetToRoom();

if (persist)
PersistState();
EmitSignal(SignalName.FrameBindingsChanged);
return true;
}

public string GetBindingKind(string frameId)
{
if (_bindingByFrame.TryGetValue(frameId, out var kind))
return kind;
return BindingStatic;
}

public bool SetBindingKind(string frameId, string bindingKind, bool persist = true)
{
if (_frameService == null)
return false;
if (!_frameService.TryGetFrame(frameId, out var frame))
return false;

bindingKind = NormalizeBindingKind(bindingKind);
_bindingByFrame[frameId] = bindingKind;
ApplyBindingToFrame(frameId, frame);

if (persist)
PersistState();
EmitSignal(SignalName.FrameBindingsChanged);
return true;
}

public string GetFramePreset(string frameId)
{
if (_framePresetByFrame.TryGetValue(frameId, out var preset))
return preset;
return SupportedFramePresets[0];
}

public bool SetFramePreset(string frameId, string framePreset, bool persist = true)
{
if (_frameService == null)
return false;
if (!_frameService.TryGetFrame(frameId, out var frame))
return false;

framePreset = NormalizeFramePreset(framePreset);
_framePresetByFrame[frameId] = framePreset;
ApplyFramePresetToFrame(frameId, frame);

if (persist)
PersistState();
EmitSignal(SignalName.FrameBindingsChanged);
return true;
}

public long GetDesktopWindowForFrame(string frameId)
{
if (_desktopWindowByFrame.TryGetValue(frameId, out var windowId))
return windowId;
return 0;
}

public bool SetDesktopWindowForFrame(string frameId, long windowId, bool persist = true)
{
if (_frameService == null)
return false;

_desktopWindowByFrame[frameId] = windowId;
if (_frameService.TryGetFrame(frameId, out var frame) && _frameService.GetFrameChartType(frameId) == "desktop")
ApplyDesktopBinding(frameId, frame);

if (persist)
PersistState();
EmitSignal(SignalName.FrameBindingsChanged);
return true;
}

public Array<GDDict> ListDesktopWindows()
{
var windows = new Array<GDDict>();
if (_desktopPrototypeTexture == null || !_desktopPrototypeTexture.HasMethod("get_available_windows"))
return windows;

var raw = _desktopPrototypeTexture.Call("get_available_windows").AsGodotArray();
foreach (Variant item in raw)
{
var asDict = item.AsGodotDictionary();
var id = asDict.TryGetValue("id", out var idVariant) ? idVariant.AsInt64() : 0;
var title = asDict.TryGetValue("title", out var titleVariant) ? titleVariant.AsString() : "";
if (id <= 0)
continue;
windows.Add(new GDDict
{
{ "id", id },
{ "title", title },
});
}
return windows;
}

public override void _Process(double delta)
{
_streamAccumulator += delta;
if (_streamAccumulator < StreamTickSeconds)
return;
_streamAccumulator = 0.0;

foreach (var frameId in _stateByFrame.Keys)
{
if (_stateByFrame[frameId].BindingKind != BindingStream)
continue;
if (_frameService == null || !_frameService.TryGetFrame(frameId, out var frame))
continue;
TickStreamBinding(frameId, frame);
}
}

private void ResolveDesktopPrototypeTexture()
{
if (_dataRoom == null)
return;

var panel = _dataRoom.GetNodeOrNull<MeshInstance3D>("DesktopPanel");
if (panel == null)
return;

var mat = panel.GetSurfaceOverrideMaterial(0) as StandardMaterial3D;
if (mat == null)
return;

if (mat.AlbedoTexture is Texture2D texture && texture.HasMethod("get_available_windows"))
_desktopPrototypeTexture = texture;
}

private void ResolveEnvironmentNodes()
{
if (_dataRoom == null)
return;

_worldEnvironment = _dataRoom.GetNodeOrNull<WorldEnvironment>("WorldEnvironment");
_directionalLight = _dataRoom.GetNodeOrNull<DirectionalLight3D>("DirectionalLight3D");
_spotLightA = _dataRoom.GetNodeOrNull<SpotLight3D>("SpotLight3D");
_spotLightB = _dataRoom.GetNodeOrNull<SpotLight3D>("SpotLight3D2");

if (_worldEnvironment?.Environment == null)
_environmentStatus = "warning: missing DataRoom/WorldEnvironment";
else
_environmentStatus = "ready";
}

private void OnWorkspaceLoaded(string _workspaceName)
{
ApplyWorkspaceState();
}

private void OnRuntimeFramesChanged()
{
SyncStateToRuntimeFrames();
ApplyAllStateToRuntimeFrames();
PersistState();
EmitSignal(SignalName.FrameBindingsChanged);
}

private void ApplyWorkspaceState()
{
_bindingByFrame.Clear();
_framePresetByFrame.Clear();
_desktopWindowByFrame.Clear();
_stateByFrame.Clear();

if (_workspaceService == null)
return;

if (_workspaceService.ActiveWorkspaceProfile.TryGetValue(BindingsProfileKey, out var bindingsVariant)
&& bindingsVariant.VariantType == Variant.Type.Array)
{
var entries = bindingsVariant.AsGodotArray<GDDict>();
foreach (var entry in entries)
{
if (!entry.TryGetValue("frame_id", out var frameIdVariant))
continue;
var frameId = frameIdVariant.AsString();
if (string.IsNullOrWhiteSpace(frameId))
continue;
var bindingKind = entry.TryGetValue("binding_kind", out var kindVariant)
? kindVariant.AsString()
: BindingStatic;
_bindingByFrame[frameId] = NormalizeBindingKind(bindingKind);
}
}

if (_workspaceService.ActiveWorkspaceProfile.TryGetValue(FramePresetsProfileKey, out var presetsVariant)
&& presetsVariant.VariantType == Variant.Type.Array)
{
var entries = presetsVariant.AsGodotArray<GDDict>();
foreach (var entry in entries)
{
if (!entry.TryGetValue("frame_id", out var frameIdVariant))
continue;
var frameId = frameIdVariant.AsString();
if (string.IsNullOrWhiteSpace(frameId))
continue;
var preset = entry.TryGetValue("frame_preset", out var presetVariant)
? presetVariant.AsString()
: SupportedFramePresets[0];
_framePresetByFrame[frameId] = NormalizeFramePreset(preset);
}
}

if (_workspaceService.ActiveWorkspaceProfile.TryGetValue(DesktopWindowsProfileKey, out var windowsVariant)
&& windowsVariant.VariantType == Variant.Type.Array)
{
var entries = windowsVariant.AsGodotArray<GDDict>();
foreach (var entry in entries)
{
if (!entry.TryGetValue("frame_id", out var frameIdVariant))
continue;
var frameId = frameIdVariant.AsString();
if (string.IsNullOrWhiteSpace(frameId))
continue;
var windowId = entry.TryGetValue("window_id", out var windowVariant)
? windowVariant.AsInt64()
: 0;
_desktopWindowByFrame[frameId] = windowId;
}
}

if (_workspaceService.ActiveWorkspaceProfile.TryGetValue(EnvironmentPresetProfileKey, out var envPresetVariant))
_environmentPreset = NormalizeEnvironmentPreset(envPresetVariant.AsString());
else
_environmentPreset = SupportedEnvironmentPresets[0];

SyncStateToRuntimeFrames();
ApplyAllStateToRuntimeFrames();
ApplyEnvironmentPresetToRoom();
PersistState();
EmitSignal(SignalName.FrameBindingsChanged);
}

private void ApplyEnvironmentPresetToRoom()
{
if (_worldEnvironment?.Environment == null)
{
_environmentStatus = "warning: environment node missing, preset not applied";
if (!_loggedMissingEnvironmentNodes)
{
_loggedMissingEnvironmentNodes = true;
GD.PushWarning("Environment preset requested but DataRoom/WorldEnvironment is unavailable.");
}
return;
}

var env = _worldEnvironment.Environment;
var hdriApplied = TryApplyHdriSky(env, _environmentPreset, out var hdriSourcePath);

switch (_environmentPreset)
{
case "studio":
if (!hdriApplied)
{
env.BackgroundMode = Godot.Environment.BGMode.Color;
env.BackgroundColor = new Color(0.14f, 0.16f, 0.19f, 1f);
}
env.AmbientLightSource = Godot.Environment.AmbientSource.Color;
env.AmbientLightColor = new Color(0.70f, 0.76f, 0.84f, 1f);
env.AmbientLightEnergy = 0.55f;
env.TonemapExposure = 0.8f;
env.GlowEnabled = true;
ApplyLightPreset(new Color(0.90f, 0.93f, 1f, 1f), 0.8f, 0.95f);
break;
case "night":
if (!hdriApplied)
{
env.BackgroundMode = Godot.Environment.BGMode.Color;
env.BackgroundColor = new Color(0.04f, 0.05f, 0.09f, 1f);
}
env.AmbientLightSource = Godot.Environment.AmbientSource.Color;
env.AmbientLightColor = new Color(0.27f, 0.36f, 0.53f, 1f);
env.AmbientLightEnergy = 0.35f;
env.TonemapExposure = 0.65f;
env.GlowEnabled = false;
ApplyLightPreset(new Color(0.56f, 0.72f, 0.97f, 1f), 0.32f, 0.58f);
break;
default:
if (!hdriApplied)
{
env.BackgroundMode = Godot.Environment.BGMode.Color;
env.BackgroundColor = new Color(0.4600764f, 0.9797395f, 0.6366237f, 1f);
}
env.AmbientLightSource = Godot.Environment.AmbientSource.Color;
env.AmbientLightColor = new Color(0.8f, 0.8f, 0.9f, 1f);
env.AmbientLightEnergy = 0.6f;
env.TonemapExposure = 1.0f;
env.GlowEnabled = true;
ApplyLightPreset(new Color(0.4506024f, 0.6884674f, 0.97673804f, 1f), 0.5f, 1.0f);
break;
}

var missingLights = new System.Collections.Generic.List<string>();
if (_directionalLight == null)
missingLights.Add("DirectionalLight3D");
if (_spotLightA == null)
missingLights.Add("SpotLight3D");
if (_spotLightB == null)
missingLights.Add("SpotLight3D2");

if (missingLights.Count == 0)
_environmentStatus = hdriApplied
? $"ready ({_environmentPreset}, hdri: {hdriSourcePath})"
: $"ready ({_environmentPreset}, fallback: color sky)";
else
_environmentStatus = hdriApplied
? $"partial ({_environmentPreset}, hdri: {hdriSourcePath}): missing {string.Join(", ", missingLights)}"
: $"partial ({_environmentPreset}, fallback: color sky): missing {string.Join(", ", missingLights)}";
}

private static bool TryApplyHdriSky(Godot.Environment env, string environmentPreset, out string sourcePath)
{
sourcePath = "";
foreach (var path in GetHdriCandidates(environmentPreset))
{
if (!ResourceLoader.Exists(path))
continue;

var panorama = GD.Load<Texture2D>(path);
if (panorama == null)
continue;

var skyMaterial = new PanoramaSkyMaterial
{
Panorama = panorama,
};

var sky = new Sky
{
SkyMaterial = skyMaterial,
};

env.Sky = sky;
env.BackgroundMode = Godot.Environment.BGMode.Sky;
sourcePath = path;
return true;
}

return false;
}

private static string[] GetHdriCandidates(string environmentPreset)
{
return environmentPreset switch
{
"studio" => StudioHdriCandidates,
"night" => NightHdriCandidates,
_ => DaylightHdriCandidates,
};
}

private void ApplyLightPreset(Color keyLightColor, float keyLightEnergy, float spotMultiplier)
{
if (_directionalLight != null)
{
_directionalLight.LightColor = keyLightColor;
_directionalLight.LightEnergy = keyLightEnergy;
}

if (_spotLightA != null)
_spotLightA.LightEnergy = spotMultiplier;
if (_spotLightB != null)
_spotLightB.LightEnergy = spotMultiplier;
}

private void SyncStateToRuntimeFrames()
{
if (_frameService == null)
return;

var activeIds = new HashSet<string>();
foreach (var profile in _frameService.ListRuntimeFrameProfiles())
{
if (!profile.TryGetValue("id", out var idVariant))
continue;
var frameId = idVariant.AsString();
if (string.IsNullOrWhiteSpace(frameId))
continue;
activeIds.Add(frameId);

if (!_bindingByFrame.ContainsKey(frameId))
_bindingByFrame[frameId] = BindingStatic;
if (!_framePresetByFrame.ContainsKey(frameId))
_framePresetByFrame[frameId] = SupportedFramePresets[0];
if (!_desktopWindowByFrame.ContainsKey(frameId))
_desktopWindowByFrame[frameId] = 0;
}

var removed = new List<string>();
foreach (var frameId in _bindingByFrame.Keys)
{
if (!activeIds.Contains(frameId))
removed.Add(frameId);
}
foreach (var frameId in removed)
{
_bindingByFrame.Remove(frameId);
_framePresetByFrame.Remove(frameId);
_desktopWindowByFrame.Remove(frameId);
_stateByFrame.Remove(frameId);
}
}

private void ApplyAllStateToRuntimeFrames()
{
if (_frameService == null)
return;

foreach (var profile in _frameService.ListRuntimeFrameProfiles())
{
if (!profile.TryGetValue("id", out var idVariant))
continue;
var frameId = idVariant.AsString();
if (string.IsNullOrWhiteSpace(frameId))
continue;
if (_frameService.TryGetFrame(frameId, out var frame))
ApplyBindingToFrame(frameId, frame);
}
}

private void ApplyBindingToFrame(string frameId, ChartFrame3D frame)
{
ApplyFramePresetToFrame(frameId, frame);

var chartType = _frameService != null ? _frameService.GetFrameChartType(frameId) : "bar";
if (chartType == "desktop")
{
ApplyDesktopBinding(frameId, frame);
return;
}

var chartNode = FindRuntimeChart(frame);
if (chartNode == null)
return;

var bindingKind = GetBindingKind(frameId);
if (!_stateByFrame.TryGetValue(frameId, out var state))
{
state = new RuntimeBindingState();
_stateByFrame[frameId] = state;
}
state.BindingKind = bindingKind;

if (bindingKind == BindingStream)
ApplyStreamBinding(frameId, chartType, chartNode, state);
else
ApplyStaticBinding(chartType, chartNode, state);
}

private void ApplyDesktopBinding(string frameId, ChartFrame3D frame)
{
var desktopView = FindDesktopView(frame);
if (desktopView == null)
return;

if (!_stateByFrame.TryGetValue(frameId, out var state))
{
state = new RuntimeBindingState();
_stateByFrame[frameId] = state;
}

state.DesktopTexture ??= CloneDesktopCaptureTexture();
if (state.DesktopTexture == null)
return;

desktopView.BindFrame(frame);
desktopView.SetCaptureTexture(state.DesktopTexture);

var selectedWindow = GetDesktopWindowForFrame(frameId);
if (selectedWindow <= 0)
{
selectedWindow = PickDefaultDesktopWindowId();
if (selectedWindow > 0)
_desktopWindowByFrame[frameId] = selectedWindow;
}

if (selectedWindow > 0)
desktopView.SetWindowId(selectedWindow);
}

private Texture2D? CloneDesktopCaptureTexture()
{
if (_desktopPrototypeTexture == null)
return null;

if (_desktopPrototypeTexture.Duplicate(true) is not Texture2D clone)
return null;

clone.Set("capture_cursor", false);
clone.Set("enabled", true);
return clone;
}

private long PickDefaultDesktopWindowId()
{
var windows = ListDesktopWindows();
foreach (var window in windows)
{
var id = window.TryGetValue("id", out var idVariant) ? idVariant.AsInt64() : 0;
var title = window.TryGetValue("title", out var titleVariant) ? titleVariant.AsString() : "";
if (id <= 0)
continue;
if (!string.IsNullOrWhiteSpace(title) && title.Contains("Godot", StringComparison.OrdinalIgnoreCase))
continue;
return id;
}

if (windows.Count > 0 && windows[0].TryGetValue("id", out var fallbackVariant))
return fallbackVariant.AsInt64();
return 0;
}

private static RuntimeDesktopFrameView? FindDesktopView(ChartFrame3D frame)
{
foreach (var child in frame.GetChildren())
{
if (child is RuntimeDesktopFrameView desktopView)
return desktopView;
}
return null;
}

private void ApplyFramePresetToFrame(string frameId, ChartFrame3D frame)
{
var preset = GetFramePreset(frameId);
switch (preset)
{
case "focus":
frame.BackgroundColor = new Color(0.08f, 0.12f, 0.18f, 1f);
frame.BorderColor = new Color(0.35f, 0.80f, 0.95f, 1f);
break;
case "presentation":
frame.BackgroundColor = new Color(0.15f, 0.14f, 0.12f, 1f);
frame.BorderColor = new Color(0.94f, 0.72f, 0.42f, 1f);
break;
default:
frame.BackgroundColor = new Color(0.10f, 0.10f, 0.12f, 1f);
frame.BorderColor = new Color(0.45f, 0.45f, 0.50f, 1f);
break;
}
}

private static Chart3D? FindRuntimeChart(ChartFrame3D frame)
{
foreach (var child in frame.GetChildren())
{
if (child is Chart3D chart3D)
return chart3D;
}
return null;
}

private static void ApplyStaticBinding(string chartType, Chart3D chartNode, RuntimeBindingState state)
{
state.StreamDataSource = null;
state.DictDataSource = null;
state.Phase = 0f;

switch (chartType)
{
case "network":
state.DictDataSource = new DictDataSource { SourceData = BuildStaticNetworkData() };
chartNode.DataSource = state.DictDataSource;
break;
case "surface":
chartNode.DataSource = null;
if (chartNode is SurfaceChart3D surface)
surface.GridData = BuildSurfaceGrid(0f);
break;
case "histogram":
chartNode.DataSource = null;
if (chartNode is HistogramChart3D hist)
hist.RawData = BuildHistogramData(0f);
break;
case "scatter":
state.DictDataSource = new DictDataSource { SourceData = BuildStaticScatterData() };
chartNode.DataSource = state.DictDataSource;
break;
case "circuit":
chartNode.DataSource = null;
break;
default:
state.DictDataSource = new DictDataSource { SourceData = BuildStaticSeriesData() };
chartNode.DataSource = state.DictDataSource;
break;
}
}

private static void ApplyStreamBinding(string frameId, string chartType, Chart3D chartNode, RuntimeBindingState state)
{
state.Phase = (Math.Abs(state.Phase) < 0.001f) ? FramePhaseSeed(frameId) : state.Phase;

switch (chartType)
{
case "network":
state.DictDataSource = new DictDataSource { SourceData = BuildStaticNetworkData() };
chartNode.DataSource = state.DictDataSource;
state.StreamDataSource = null;
break;
case "surface":
chartNode.DataSource = null;
if (chartNode is SurfaceChart3D surface)
surface.GridData = BuildSurfaceGrid(state.Phase);
state.StreamDataSource = null;
state.DictDataSource = null;
break;
case "histogram":
chartNode.DataSource = null;
if (chartNode is HistogramChart3D hist)
hist.RawData = BuildHistogramData(state.Phase);
state.StreamDataSource = null;
state.DictDataSource = null;
break;
case "scatter":
state.StreamDataSource = null;
state.DictDataSource ??= new DictDataSource();
state.DictDataSource.SourceData = BuildScatterStreamData(state.Phase);
chartNode.DataSource = state.DictDataSource;
break;
case "circuit":
chartNode.DataSource = null;
state.StreamDataSource = null;
state.DictDataSource = null;
break;
default:
state.DictDataSource = null;
state.StreamDataSource ??= new StreamDataSource { MaxWindow = 18 };
chartNode.DataSource = state.StreamDataSource;
SeedStreamSeries(state.StreamDataSource, state.Phase);
break;
}
}

private void TickStreamBinding(string frameId, ChartFrame3D frame)
{
if (!_stateByFrame.TryGetValue(frameId, out var state))
return;
var chartNode = FindRuntimeChart(frame);
if (chartNode == null)
return;

state.Phase += 0.45f;
var chartType = _frameService != null ? _frameService.GetFrameChartType(frameId) : "bar";
switch (chartType)
{
case "surface":
if (chartNode is SurfaceChart3D surface)
surface.GridData = BuildSurfaceGrid(state.Phase);
break;
case "histogram":
if (chartNode is HistogramChart3D histogram)
histogram.RawData = BuildHistogramData(state.Phase);
break;
case "scatter":
state.DictDataSource ??= new DictDataSource();
state.DictDataSource.SourceData = BuildScatterStreamData(state.Phase);
chartNode.DataSource = state.DictDataSource;
break;
case "network":
break;
case "circuit":
break;
default:
state.StreamDataSource ??= new StreamDataSource { MaxWindow = 18 };
chartNode.DataSource = state.StreamDataSource;
state.StreamDataSource.AppendFrame(new System.Collections.Generic.Dictionary<string, double>
{
{ "Signal A", 2.2 + Math.Sin(state.Phase) * 1.1 },
{ "Signal B", 1.8 + Math.Cos(state.Phase * 0.85f) * 0.9 },
});
break;
}
}

private void PersistState()
{
if (_workspaceService == null)
return;

var bindings = new GDArray();
foreach (var frameId in _bindingByFrame.Keys)
{
bindings.Add(new GDDict
{
{ "frame_id", frameId },
{ "binding_kind", _bindingByFrame[frameId] },
});
}

var presets = new GDArray();
foreach (var frameId in _framePresetByFrame.Keys)
{
presets.Add(new GDDict
{
{ "frame_id", frameId },
{ "frame_preset", _framePresetByFrame[frameId] },
});
}

var windows = new GDArray();
foreach (var frameId in _desktopWindowByFrame.Keys)
{
windows.Add(new GDDict
{
{ "frame_id", frameId },
{ "window_id", _desktopWindowByFrame[frameId] },
});
}

_workspaceService.ActiveWorkspaceProfile[BindingsProfileKey] = bindings;
_workspaceService.ActiveWorkspaceProfile[FramePresetsProfileKey] = presets;
_workspaceService.ActiveWorkspaceProfile[DesktopWindowsProfileKey] = windows;
_workspaceService.ActiveWorkspaceProfile[EnvironmentPresetProfileKey] = _environmentPreset;
_workspaceService.SaveActiveWorkspace();
}

private static string NormalizeBindingKind(string bindingKind)
{
if (string.IsNullOrWhiteSpace(bindingKind))
return BindingStatic;
var lowered = bindingKind.Trim().ToLowerInvariant();
foreach (var candidate in SupportedBindingKinds)
{
if (candidate == lowered)
return candidate;
}
return BindingStatic;
}

private static string NormalizeFramePreset(string framePreset)
{
if (string.IsNullOrWhiteSpace(framePreset))
return SupportedFramePresets[0];
var lowered = framePreset.Trim().ToLowerInvariant();
foreach (var candidate in SupportedFramePresets)
{
if (candidate == lowered)
return candidate;
}
return SupportedFramePresets[0];
}

private static string NormalizeEnvironmentPreset(string environmentPreset)
{
if (string.IsNullOrWhiteSpace(environmentPreset))
return SupportedEnvironmentPresets[0];
var lowered = environmentPreset.Trim().ToLowerInvariant();
foreach (var candidate in SupportedEnvironmentPresets)
{
if (candidate == lowered)
return candidate;
}
return SupportedEnvironmentPresets[0];
}

private static void SeedStreamSeries(StreamDataSource source, float phase)
{
source.ClearData();
for (var i = 0; i < 10; i++)
{
var step = phase + i * 0.35f;
source.AppendFrame(new System.Collections.Generic.Dictionary<string, double>
{
{ "Signal A", 2.0 + Math.Sin(step) * 1.0 },
{ "Signal B", 1.5 + Math.Cos(step * 0.85f) * 0.8 },
});
}
}

private static float FramePhaseSeed(string frameId)
{
var hash = Math.Abs(frameId.GetHashCode());
return (hash % 628) / 100f;
}

private static GDDict BuildStaticSeriesData()
{
return new GDDict
{
{ "labels", new GDArray { "A", "B", "C", "D", "E" } },
{ "datasets", new GDArray
{
new GDDict { { "name", "Alpha" }, { "values", new GDArray { 2.2, 3.1, 2.6, 4.4, 3.8 } } },
new GDDict { { "name", "Beta" }, { "values", new GDArray { 1.1, 2.4, 3.6, 2.9, 3.2 } } },
}
},
};
}

private static GDDict BuildStaticScatterData()
{
return BuildScatterStreamData(0f);
}

private static GDDict BuildScatterStreamData(float phase)
{
var pointsA = new GDArray();
var pointsB = new GDArray();
for (var i = 0; i < 16; i++)
{
var x = i * 0.22f;
pointsA.Add(new Vector3(x, 1.2f + MathF.Sin(x + phase) * 0.7f, 0.3f + MathF.Cos(x * 0.5f + phase) * 0.35f));
pointsB.Add(new Vector3(x, 1.0f + MathF.Cos(x * 0.7f + phase) * 0.9f, -0.25f + MathF.Sin(x + phase) * 0.4f));
}

return new GDDict
{
{ "datasets", new GDArray
{
new GDDict { { "name", "Cluster A" }, { "points", pointsA } },
new GDDict { { "name", "Cluster B" }, { "points", pointsB } },
}
},
};
}

private static GDDict BuildStaticNetworkData()
{
return new GDDict
{
{ "nodes", new GDArray
{
new GDDict { { "id", "A" }, { "label", "Ingest" }, { "x", -0.9 }, { "y", 0.2 }, { "z", -0.2 } },
new GDDict { { "id", "B" }, { "label", "Feature" }, { "x", -0.2 }, { "y", 0.6 }, { "z", 0.3 } },
new GDDict { { "id", "C" }, { "label", "Train" }, { "x", 0.55 }, { "y", 0.45 }, { "z", -0.15 } },
new GDDict { { "id", "D" }, { "label", "Serve" }, { "x", 1.05 }, { "y", 0.15 }, { "z", 0.25 } },
}
},
{ "edges", new GDArray
{
new GDDict { { "source", "A" }, { "target", "B" }, { "label", "events" }, { "weight", 0.7 } },
new GDDict { { "source", "B" }, { "target", "C" }, { "label", "features" }, { "weight", 0.9 } },
new GDDict { { "source", "C" }, { "target", "D" }, { "label", "model" }, { "weight", 0.8 } },
}
},
};
}

private static GDArray BuildSurfaceGrid(float phase)
{
const int rows = 18;
const int cols = 18;
var grid = new GDArray();
for (var z = 0; z < rows; z++)
{
var row = new GDArray();
for (var x = 0; x < cols; x++)
{
var fx = x / (float)(cols - 1);
var fz = z / (float)(rows - 1);
var value = 0.5f + 0.45f * MathF.Sin((fx * MathF.Tau * 1.3f) + phase) * MathF.Cos((fz * MathF.Tau) + phase * 0.5f);
row.Add((double)value);
}
grid.Add(row);
}
return grid;
}

private static double[] BuildHistogramData(float phase)
{
var values = new double[64];
for (var i = 0; i < values.Length; i++)
{
var t = phase + i * 0.21f;
values[i] = 2.6 + Math.Sin(t) * 0.9 + Math.Cos(t * 0.47f) * 0.55;
}
return values;
}

private sealed class RuntimeBindingState
{
public string BindingKind { get; set; } = BindingStatic;
public float Phase { get; set; }
public StreamDataSource? StreamDataSource { get; set; }
public DictDataSource? DictDataSource { get; set; }
public Texture2D? DesktopTexture { get; set; }
}
}
