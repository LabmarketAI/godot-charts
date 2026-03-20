using Godot;
using GodotCharts;

public partial class RuntimeDesktopFrameView : Node3D
{
	private ChartFrame3D? _frame;
	private MeshInstance3D? _meshInstance;
	private StandardMaterial3D? _material;
	private Texture2D? _captureTexture;

	public override void _Ready()
	{
		EnsureVisuals();
	}

	public void BindFrame(ChartFrame3D frame)
	{
		if (_frame != null)
			_frame.Resized -= OnFrameResized;

		_frame = frame;
		_frame.Resized += OnFrameResized;
		FitToFrame();
	}

	public void SetCaptureTexture(Texture2D? texture)
	{
		_captureTexture = texture;
		EnsureVisuals();
		if (_material != null)
			_material.AlbedoTexture = _captureTexture;

		if (_captureTexture != null)
		{
			_captureTexture.Set("capture_cursor", false);
			_captureTexture.Set("enabled", true);
		}
	}

	public void SetWindowId(long windowId)
	{
		if (_captureTexture == null)
			return;
		_captureTexture.Set("window_id", windowId);
		_captureTexture.Set("enabled", true);
	}

	public void FitToFrame()
	{
		if (_frame == null || _meshInstance == null)
			return;

		var inner = _frame.GetInnerSize();
		if (_meshInstance.Mesh is QuadMesh quad)
			quad.Size = inner;

		_meshInstance.Position = new Vector3(
			_frame.Padding + inner.X * 0.5f,
			_frame.Padding + inner.Y * 0.5f,
			0.006f);
	}

	private void OnFrameResized(Vector2 _newSize)
	{
		FitToFrame();
	}

	private void EnsureVisuals()
	{
		if (_meshInstance != null)
			return;

		_material = new StandardMaterial3D
		{
			ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
			CullMode = BaseMaterial3D.CullModeEnum.Disabled,
			Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
			AlbedoTexture = _captureTexture,
		};

		_meshInstance = new MeshInstance3D
		{
			Name = "DesktopSurface",
			Mesh = new QuadMesh { Size = new Vector2(3f, 2f) },
			MaterialOverride = _material,
			CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
		};
		AddChild(_meshInstance);
	}
}
