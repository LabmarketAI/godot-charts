using System;
using Godot;
using GDDict = Godot.Collections.Dictionary;

public partial class ConsoleRoot : Node3D
{
private const string XrViewportScenePath = "res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn";

public bool PreferXrInteraction { get; set; }

private WorkspaceStateService? _workspaceService;
private FrameOrchestrationService? _frameService;
private DataBindingService? _bindingService;
private SubViewport? _subViewport;
private Node3D? _xrViewportHost;
private OptionButton? _workspacePicker;
private OptionButton? _framePicker;
private OptionButton? _chartTypePicker;
private OptionButton? _sizePresetPicker;
private OptionButton? _bindingKindPicker;
private OptionButton? _framePresetPicker;
private OptionButton? _monitorPicker;
private OptionButton? _windowPicker;
private OptionButton? _environmentPresetPicker;
private Label? _statusLabel;
private Label? _environmentStatusLabel;
private Label? _desktopSourceStatusLabel;

public bool IsConsoleVisible => Visible;

public override void _Ready()
{
BuildPanel();
Visible = false;
}

public void BindWorkspaceService(WorkspaceStateService service)
{
_workspaceService = service;
_workspaceService.WorkspaceLoaded += OnWorkspaceLoaded;
_workspaceService.WorkspaceListChanged += RefreshWorkspaceList;
RefreshWorkspaceList();
}

public void BindFrameService(FrameOrchestrationService service)
{
_frameService = service;
_frameService.RuntimeFramesChanged += RefreshFrameList;
RefreshFrameList();
}

public void BindBindingService(DataBindingService service)
{
_bindingService = service;
_bindingService.FrameBindingsChanged += RefreshFrameControlsForCurrentSelection;
RefreshFrameControlsForCurrentSelection();
}

public void ToggleConsole()
{
SetConsoleVisible(!Visible);
}

public void SetConsoleVisible(bool show)
{
Visible = show;
if (_statusLabel != null)
_statusLabel.Text = show ? "Console: Visible" : "Console: Hidden";
}

private void BuildPanel()
{
		var useXrViewportHost = PreferXrInteraction
			&& ProjectSettings.HasSetting("diegetic_console/use_xr_viewport_host")
			&& ProjectSettings.GetSetting("diegetic_console/use_xr_viewport_host").AsBool();

		if (useXrViewportHost && FileAccess.FileExists(XrViewportScenePath))
{
var packed = GD.Load<PackedScene>(XrViewportScenePath);
			if (packed != null)
			{
				_xrViewportHost = packed.Instantiate<Node3D>();
				_xrViewportHost.Name = "ConsoleViewportHost";
				_xrViewportHost.Set("screen_size", new Vector2(1.8f, 1.1f));
				_xrViewportHost.Set("viewport_size", new Vector2(1024f, 640f));
				_xrViewportHost.Set("input_keyboard", true);
				_xrViewportHost.Set("input_gamepad", false);
				AddChild(_xrViewportHost);

				_subViewport = _xrViewportHost.GetNodeOrNull<SubViewport>("Viewport");
			}
}

if (_subViewport == null)
{
_subViewport = new SubViewport
{
Name = "ConsoleViewport",
Size = new Vector2I(1024, 640),
TransparentBg = false,
Disable3D = true,
RenderTargetUpdateMode = SubViewport.UpdateMode.WhenVisible,
RenderTargetClearMode = SubViewport.ClearMode.Always,
};
AddChild(_subViewport);
}

var uiRoot = new ColorRect
{
Color = new Color(0.05f, 0.06f, 0.08f, 0.95f),
CustomMinimumSize = new Vector2(1024, 640),
Size = new Vector2(1024, 640),
};
_subViewport.AddChild(uiRoot);

var margin = new MarginContainer
{
OffsetLeft = 24,
OffsetTop = 24,
OffsetRight = 1000,
OffsetBottom = 616,
};
uiRoot.AddChild(margin);

var column = new VBoxContainer();
column.AddThemeConstantOverride("separation", 10);
margin.AddChild(column);

column.AddChild(new Label
{
Text = "Diegetic Console (Phase 4 scaffold)",
ThemeTypeVariation = "HeaderSmall",
});

_statusLabel = new Label { Text = "Console: Hidden" };
column.AddChild(_statusLabel);

_environmentStatusLabel = new Label { Text = "Environment: pending" };
column.AddChild(_environmentStatusLabel);

_desktopSourceStatusLabel = new Label { Text = "Desktop source: pending" };
column.AddChild(_desktopSourceStatusLabel);

var row = new HBoxContainer();
row.AddThemeConstantOverride("separation", 8);
column.AddChild(row);

_workspacePicker = new OptionButton();
_workspacePicker.ItemSelected += OnWorkspaceSelected;
row.AddChild(_workspacePicker);

var newBtn = new Button { Text = "New" };
newBtn.Pressed += OnNewWorkspacePressed;
row.AddChild(newBtn);

var saveBtn = new Button { Text = "Save" };
saveBtn.Pressed += OnSaveWorkspacePressed;
row.AddChild(saveBtn);

var deleteBtn = new Button { Text = "Delete" };
deleteBtn.Pressed += OnDeleteWorkspacePressed;
row.AddChild(deleteBtn);

column.AddChild(new HSeparator());
column.AddChild(new Label { Text = "Runtime Frames" });

var frameRow = new HBoxContainer();
frameRow.AddThemeConstantOverride("separation", 8);
column.AddChild(frameRow);

_framePicker = new OptionButton();
_framePicker.ItemSelected += OnFrameSelected;
frameRow.AddChild(_framePicker);

_chartTypePicker = new OptionButton();
foreach (var chartType in FrameOrchestrationService.SupportedChartTypes)
_chartTypePicker.AddItem(chartType);
frameRow.AddChild(_chartTypePicker);

_sizePresetPicker = new OptionButton();
foreach (var sizePreset in FrameOrchestrationService.SupportedSizePresets)
_sizePresetPicker.AddItem(sizePreset);
_sizePresetPicker.Select(1); // medium
frameRow.AddChild(_sizePresetPicker);

_bindingKindPicker = new OptionButton();
foreach (var bindingKind in DataBindingService.SupportedBindingKinds)
_bindingKindPicker.AddItem(bindingKind);
frameRow.AddChild(_bindingKindPicker);

_framePresetPicker = new OptionButton();
foreach (var framePreset in DataBindingService.SupportedFramePresets)
_framePresetPicker.AddItem(framePreset);
frameRow.AddChild(_framePresetPicker);

var frameActionRow = new HBoxContainer();
frameActionRow.AddThemeConstantOverride("separation", 8);
column.AddChild(frameActionRow);

var createFrameBtn = new Button { Text = "Create Frame" };
createFrameBtn.Pressed += OnCreateFramePressed;
frameActionRow.AddChild(createFrameBtn);

var applyChartBtn = new Button { Text = "Set Chart" };
applyChartBtn.Pressed += OnSetChartPressed;
frameActionRow.AddChild(applyChartBtn);

var applySizeBtn = new Button { Text = "Set Size" };
applySizeBtn.Pressed += OnSetSizePressed;
frameActionRow.AddChild(applySizeBtn);

var deleteFrameBtn = new Button { Text = "Delete Frame" };
deleteFrameBtn.Pressed += OnDeleteFramePressed;
frameActionRow.AddChild(deleteFrameBtn);

var applyBindingBtn = new Button { Text = "Set Binding" };
applyBindingBtn.Pressed += OnSetBindingPressed;
frameActionRow.AddChild(applyBindingBtn);

var applyPresetBtn = new Button { Text = "Set Preset" };
applyPresetBtn.Pressed += OnSetFramePresetPressed;
frameActionRow.AddChild(applyPresetBtn);

var windowRow = new HBoxContainer();
windowRow.AddThemeConstantOverride("separation", 8);
column.AddChild(windowRow);

_monitorPicker = new OptionButton();
_monitorPicker.ItemSelected += OnMonitorSelected;
windowRow.AddChild(_monitorPicker);

var applyMonitorBtn = new Button { Text = "Set Monitor" };
applyMonitorBtn.Pressed += OnSetDesktopMonitorPressed;
windowRow.AddChild(applyMonitorBtn);

_windowPicker = new OptionButton();
windowRow.AddChild(_windowPicker);

var refreshWindowsBtn = new Button { Text = "Refresh Windows" };
refreshWindowsBtn.Pressed += OnRefreshWindowsPressed;
windowRow.AddChild(refreshWindowsBtn);

var applyWindowBtn = new Button { Text = "Set Window" };
applyWindowBtn.Pressed += OnSetDesktopWindowPressed;
windowRow.AddChild(applyWindowBtn);

var environmentRow = new HBoxContainer();
environmentRow.AddThemeConstantOverride("separation", 8);
column.AddChild(environmentRow);

_environmentPresetPicker = new OptionButton();
foreach (var environmentPreset in DataBindingService.SupportedEnvironmentPresets)
_environmentPresetPicker.AddItem(environmentPreset);
environmentRow.AddChild(_environmentPresetPicker);

var applyEnvironmentBtn = new Button { Text = "Set Environment" };
applyEnvironmentBtn.Pressed += OnSetEnvironmentPresetPressed;
environmentRow.AddChild(applyEnvironmentBtn);

column.AddChild(new Label
{
Text = "F1 toggles this panel. Workspace persistence is active in user://workspaces.",
});

if (_xrViewportHost == null)
{
var panelMesh = new QuadMesh
{
Size = new Vector2(1.8f, 1.1f),
};
var panelMaterial = new StandardMaterial3D
{
AlbedoTexture = _subViewport.GetTexture(),
ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
CullMode = BaseMaterial3D.CullModeEnum.Disabled,
Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
};

var panel = new MeshInstance3D
{
Name = "ConsolePanel",
Mesh = panelMesh,
MaterialOverride = panelMaterial,
};
AddChild(panel);
}
}

private void RefreshWorkspaceList()
{
if (_workspaceService == null || _workspacePicker == null)
return;

_workspacePicker.Clear();
var names = _workspaceService.ListWorkspaceNames();
for (var i = 0; i < names.Length; i++)
_workspacePicker.AddItem(names[i]);

if (names.Length == 0)
return;

var active = _workspaceService.ActiveWorkspaceName;
var selected = Array.IndexOf(names, active);
if (selected < 0)
selected = 0;
_workspacePicker.Select(selected);
}

private void RefreshFrameList()
{
if (_frameService == null || _framePicker == null)
return;

_framePicker.Clear();
var profiles = _frameService.ListRuntimeFrameProfiles();
for (var i = 0; i < profiles.Count; i++)
{
var profile = profiles[i];
var id = profile.TryGetValue("id", out var idVariant) ? idVariant.AsString() : $"frame-{i}";
var chart = profile.TryGetValue("chart_type", out var chartVariant) ? chartVariant.AsString() : "bar";
_framePicker.AddItem($"{id} ({chart})");
}

if (_framePicker.ItemCount > 0)
_framePicker.Select(0);

RefreshFrameControlsForCurrentSelection();
}

private void RefreshFrameControlsForCurrentSelection()
{
RefreshBindingSelectionForCurrentFrame();
RefreshFramePresetSelectionForCurrentFrame();
RefreshDesktopWindows();
RefreshEnvironmentSelection();
}

private void RefreshEnvironmentSelection()
{
if (_bindingService == null || _environmentPresetPicker == null)
return;

var preset = _bindingService.GetEnvironmentPreset();
for (var i = 0; i < _environmentPresetPicker.ItemCount; i++)
{
if (_environmentPresetPicker.GetItemText(i) == preset)
{
_environmentPresetPicker.Select(i);
return;
}

if (_environmentStatusLabel != null)
_environmentStatusLabel.Text = $"Environment: {_bindingService.GetEnvironmentStatus()}";
}
}

private void RefreshBindingSelectionForCurrentFrame()
{
if (_bindingService == null || _framePicker == null || _bindingKindPicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var bindingKind = _bindingService.GetBindingKind(frameId);
for (var i = 0; i < _bindingKindPicker.ItemCount; i++)
{
if (_bindingKindPicker.GetItemText(i) == bindingKind)
{
_bindingKindPicker.Select(i);
return;
}
}
}

private void RefreshFramePresetSelectionForCurrentFrame()
{
if (_bindingService == null || _framePicker == null || _framePresetPicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var framePreset = _bindingService.GetFramePreset(frameId);
for (var i = 0; i < _framePresetPicker.ItemCount; i++)
{
if (_framePresetPicker.GetItemText(i) == framePreset)
{
_framePresetPicker.Select(i);
return;
}
}
}

private void RefreshDesktopWindows()
{
if (_bindingService == null || _windowPicker == null || _monitorPicker == null || _framePicker == null || _frameService == null)
return;

_monitorPicker.Clear();
var monitors = _bindingService.ListDesktopMonitors();
for (var i = 0; i < monitors.Count; i++)
{
var monitor = monitors[i];
var index = monitor.TryGetValue("index", out var indexVariant) ? indexVariant.AsInt32() : i;
var label = monitor.TryGetValue("label", out var labelVariant) ? labelVariant.AsString() : $"Monitor {index}";
_monitorPicker.AddItem(label);
_monitorPicker.SetItemMetadata(_monitorPicker.ItemCount - 1, index);
}
if (_monitorPicker.ItemCount == 0)
{
_monitorPicker.AddItem("Monitor 0");
_monitorPicker.SetItemMetadata(0, 0);
}

_windowPicker.Clear();
_windowPicker.AddItem("(auto)");
_windowPicker.SetItemMetadata(0, new GDDict { { "id", 0L }, { "title", "" } });

if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var chartType = _frameService.GetFrameChartType(frameId);
var selectedMonitor = _bindingService.GetDesktopMonitorForFrame(frameId);
var selectedWindow = _bindingService.GetDesktopWindowForFrame(frameId);

var monitorSelectedIndex = 0;
for (var i = 0; i < _monitorPicker.ItemCount; i++)
{
if (_monitorPicker.GetItemMetadata(i).AsInt32() == selectedMonitor)
{
monitorSelectedIndex = i;
break;
}
}
_monitorPicker.Select(monitorSelectedIndex);

var windows = _bindingService.ListDesktopWindowsForMonitor(selectedMonitor);
for (var i = 0; i < windows.Count; i++)
{
var window = windows[i];
var windowId = window.TryGetValue("id", out var idVariant) ? idVariant.AsInt64() : 0;
var title = window.TryGetValue("title", out var titleVariant) ? titleVariant.AsString() : "";
if (windowId <= 0)
continue;

var safeTitle = string.IsNullOrWhiteSpace(title) ? "(untitled)" : title;
_windowPicker.AddItem($"{safeTitle} [{windowId}]");
_windowPicker.SetItemMetadata(_windowPicker.ItemCount - 1, new GDDict
{
{ "id", windowId },
{ "title", title },
});
}

var selectedIndex = 0;
for (var i = 0; i < _windowPicker.ItemCount; i++)
{
var meta = _windowPicker.GetItemMetadata(i).AsGodotDictionary();
var id = meta.TryGetValue("id", out var idVariant) ? idVariant.AsInt64() : 0;
if (id == selectedWindow)
{
selectedIndex = i;
break;
}
}
_windowPicker.Select(selectedIndex);
_monitorPicker.Disabled = chartType != "desktop";
_windowPicker.Disabled = chartType != "desktop";

if (_desktopSourceStatusLabel != null)
_desktopSourceStatusLabel.Text = $"Desktop source: {_bindingService.GetDesktopSourceStatus(frameId)}";
}

private void OnWorkspaceLoaded(string name)
{
if (_statusLabel != null)
_statusLabel.Text = $"Active workspace: {name}";
RefreshWorkspaceList();
}

private void OnWorkspaceSelected(long index)
{
if (_workspaceService == null || _workspacePicker == null)
return;
if (index < 0 || index >= _workspacePicker.ItemCount)
return;
var name = _workspacePicker.GetItemText((int)index);
_workspaceService.LoadWorkspace(name);
}

private void OnFrameSelected(long _index)
{
RefreshFrameControlsForCurrentSelection();
}

private void OnMonitorSelected(long _index)
{
RefreshDesktopWindows();
}

private void OnNewWorkspacePressed()
{
if (_workspaceService == null)
return;
var name = $"workspace-{DateTime.UtcNow:yyyyMMdd-HHmmss}";
if (_workspaceService.CreateWorkspace(name))
_workspaceService.LoadWorkspace(name);
}

private void OnSaveWorkspacePressed()
{
_workspaceService?.SaveActiveWorkspace(Visible);
if (_statusLabel != null && _workspaceService != null)
_statusLabel.Text = $"Saved workspace: {_workspaceService.ActiveWorkspaceName}";
}

private void OnDeleteWorkspacePressed()
{
if (_workspaceService == null)
return;
var current = _workspaceService.ActiveWorkspaceName;
if (string.IsNullOrEmpty(current))
return;
_workspaceService.DeleteWorkspace(current);
}

private void OnCreateFramePressed()
{
if (_frameService == null || _chartTypePicker == null || _sizePresetPicker == null)
return;

var chartType = _chartTypePicker.GetItemText(_chartTypePicker.Selected);
var sizePreset = _sizePresetPicker.GetItemText(_sizePresetPicker.Selected);
if (_frameService.CreateFrame(chartType, sizePreset))
_statusLabel!.Text = $"Created frame ({chartType}, {sizePreset})";
}

private void OnSetChartPressed()
{
if (_frameService == null || _framePicker == null || _chartTypePicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var chartType = _chartTypePicker.GetItemText(_chartTypePicker.Selected);
if (_frameService.SetFrameChartType(frameId, chartType))
_statusLabel!.Text = $"Set {frameId} to {chartType}";

RefreshDesktopWindows();
}

private void OnSetSizePressed()
{
if (_frameService == null || _framePicker == null || _sizePresetPicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var sizePreset = _sizePresetPicker.GetItemText(_sizePresetPicker.Selected);
if (_frameService.SetFrameSizePreset(frameId, sizePreset))
_statusLabel!.Text = $"Set {frameId} size to {sizePreset}";
}

private void OnDeleteFramePressed()
{
if (_frameService == null || _framePicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
if (_frameService.DeleteFrame(frameId))
_statusLabel!.Text = $"Deleted {frameId}";
}

private void OnSetBindingPressed()
{
if (_bindingService == null || _framePicker == null || _bindingKindPicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var bindingKind = _bindingKindPicker.GetItemText(_bindingKindPicker.Selected);
if (_bindingService.SetBindingKind(frameId, bindingKind))
_statusLabel!.Text = $"Set {frameId} binding to {bindingKind}";
}

private void OnSetFramePresetPressed()
{
if (_bindingService == null || _framePicker == null || _framePresetPicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var framePreset = _framePresetPicker.GetItemText(_framePresetPicker.Selected);
if (_bindingService.SetFramePreset(frameId, framePreset))
_statusLabel!.Text = $"Set {frameId} preset to {framePreset}";
}

private void OnRefreshWindowsPressed()
{
RefreshDesktopWindows();
if (_statusLabel != null)
_statusLabel.Text = "Refreshed desktop window list";
}

private void OnSetDesktopWindowPressed()
{
if (_bindingService == null || _framePicker == null || _windowPicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;
if (_windowPicker.Selected < 0 || _windowPicker.Selected >= _windowPicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var meta = _windowPicker.GetItemMetadata(_windowPicker.Selected).AsGodotDictionary();
var windowId = meta.TryGetValue("id", out var idVariant) ? idVariant.AsInt64() : 0;
var title = meta.TryGetValue("title", out var titleVariant) ? titleVariant.AsString() : "";
if (_bindingService.SetDesktopWindowForFrame(frameId, windowId))
{
var label = windowId > 0 ? windowId.ToString() : "auto";
_statusLabel!.Text = $"Set {frameId} desktop window to {label}";

if (windowId > 0)
{
var profile = DataBindingService.DesktopSourceProfile.FromDictionary(_bindingService.GetDesktopSourceProfileForFrame(frameId));
profile.TitleHint = title;
_bindingService.SetDesktopSourceForFrame(frameId, profile);
}
}

RefreshDesktopWindows();
}

private void OnSetDesktopMonitorPressed()
{
if (_bindingService == null || _framePicker == null || _monitorPicker == null)
return;
if (_framePicker.Selected < 0 || _framePicker.Selected >= _framePicker.ItemCount)
return;
if (_monitorPicker.Selected < 0 || _monitorPicker.Selected >= _monitorPicker.ItemCount)
return;

var frameId = ExtractFrameId(_framePicker.GetItemText(_framePicker.Selected));
var monitorIndex = _monitorPicker.GetItemMetadata(_monitorPicker.Selected).AsInt32();
if (_bindingService.SetDesktopMonitorForFrame(frameId, monitorIndex))
_statusLabel!.Text = $"Set {frameId} desktop monitor to {monitorIndex}";

RefreshDesktopWindows();
}

private void OnSetEnvironmentPresetPressed()
{
if (_bindingService == null || _environmentPresetPicker == null)
return;
if (_environmentPresetPicker.Selected < 0 || _environmentPresetPicker.Selected >= _environmentPresetPicker.ItemCount)
return;

var environmentPreset = _environmentPresetPicker.GetItemText(_environmentPresetPicker.Selected);
if (_bindingService.SetEnvironmentPreset(environmentPreset))
_statusLabel!.Text = $"Applied environment preset: {environmentPreset}";
}

private static string ExtractFrameId(string pickerText)
{
var idx = pickerText.IndexOf(" (", StringComparison.Ordinal);
return idx > 0 ? pickerText[..idx] : pickerText;
}
}
