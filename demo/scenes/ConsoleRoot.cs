using System;
using Godot;

public partial class ConsoleRoot : Node3D
{
	private WorkspaceStateService? _workspaceService;
	private FrameOrchestrationService? _frameService;
	private SubViewport? _subViewport;
	private OptionButton? _workspacePicker;
	private OptionButton? _framePicker;
	private OptionButton? _chartTypePicker;
	private OptionButton? _sizePresetPicker;
	private Label? _statusLabel;

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
			Text = "Diegetic Console (Phase 1 scaffold)",
			ThemeTypeVariation = "HeaderSmall",
		});

		_statusLabel = new Label { Text = "Console: Hidden" };
		column.AddChild(_statusLabel);

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

		column.AddChild(new Label
		{
			Text = "F1 toggles this panel. Workspace persistence is active in user://workspaces.",
		});

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

	private static string ExtractFrameId(string pickerText)
	{
		var idx = pickerText.IndexOf(" (", StringComparison.Ordinal);
		return idx > 0 ? pickerText[..idx] : pickerText;
	}
}
