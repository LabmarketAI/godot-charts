using Godot;

public partial class WristwatchConsoleHints : Node3D
{
	[Export]
	public Vector2I ViewportSize { get; set; } = new(720, 420);

	[Export]
	public Vector2 WatchPanelSize { get; set; } = new(0.22f, 0.13f);

	[Export(PropertyHint.MultilineText)]
	public string Instructions { get; set; } =
		"Console Controls\n"
		+ "F1 or B/Y: Toggle diegetic console\n"
		+ "Press again: Hide console\n"
		+ "\n"
		+ "VR interaction\n"
		+ "- Use left-hand pointer ray to target controls\n"
		+ "- Press trigger while aiming at a button\n"
		+ "- If clicks fail, open Issue #45 checklist\n"
		+ "\n"
		+ "Workaround\n"
		+ "- Use desktop scene to interact with controls\n"
		+ "- In VR use F1 or B/Y to show/hide panel state\n"
		+ "- Menu toggles keyboard passthrough when supported\n"
		+ "\n"
		+ "Open the console to:\n"
		+ "- Create and manage workspaces\n"
		+ "- Create/delete runtime frames\n"
		+ "- Set chart type and frame size";

	public override void _Ready()
	{
		BuildWatchPanel();
	}

	private void BuildWatchPanel()
	{
		var viewport = new SubViewport
		{
			Name = "WatchViewport",
			Size = ViewportSize,
			TransparentBg = true,
			Disable3D = true,
			RenderTargetUpdateMode = SubViewport.UpdateMode.Always,
		};
		AddChild(viewport);

		var root = new ColorRect
		{
			Color = new Color(0.04f, 0.05f, 0.08f, 0.92f),
			CustomMinimumSize = ViewportSize,
			Size = ViewportSize,
		};
		viewport.AddChild(root);

		var border = new PanelContainer
		{
			OffsetLeft = 12,
			OffsetTop = 12,
			OffsetRight = ViewportSize.X - 12,
			OffsetBottom = ViewportSize.Y - 12,
		};
		root.AddChild(border);

		var margin = new MarginContainer();
		margin.AddThemeConstantOverride("margin_left", 16);
		margin.AddThemeConstantOverride("margin_top", 12);
		margin.AddThemeConstantOverride("margin_right", 16);
		margin.AddThemeConstantOverride("margin_bottom", 12);
		border.AddChild(margin);

		var label = new Label
		{
			Text = Instructions,
			AutowrapMode = TextServer.AutowrapMode.WordSmart,
			HorizontalAlignment = HorizontalAlignment.Left,
			VerticalAlignment = VerticalAlignment.Top,
		};
		margin.AddChild(label);

		var mesh = new QuadMesh
		{
			Size = WatchPanelSize,
		};

		var material = new StandardMaterial3D
		{
			AlbedoTexture = viewport.GetTexture(),
			ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
			CullMode = BaseMaterial3D.CullModeEnum.Disabled,
			Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
		};

		var panel = new MeshInstance3D
		{
			Name = "WatchPanel",
			Mesh = mesh,
			MaterialOverride = material,
		};
		AddChild(panel);
	}
}
