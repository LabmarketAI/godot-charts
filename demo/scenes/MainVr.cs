// Godot Charts — VR demo.
//
// Initialises OpenXR on startup.  Run with a VR headset connected and the
// correct runtime set as the system OpenXR runtime:
//   Windows : ALVR + SteamVR  (see README — VR Quickstart)
//   Linux   : WiVRn            (see README — VR Quickstart)
//
// Controls (standard Godot XR Tools defaults)
// Left thumbstick  — direct movement (forward/back/strafe)
// Left thumbstick  — snap turn (with MovementTurn node)
// Right trigger    — aim teleport arc, release to teleport
//
// The data room is the same DataRoom subscene as the desktop demo, so any
// change to chart data or layout automatically appears in both scenes.
using Godot;

public partial class MainVr : Node3D
{
	private const string KeyboardPassthroughToggleAction = "menu_button";
	private const string ConsoleToggleButtonAction = "by_button";
	private const string ToggleConsoleAction = "toggle_diegetic_console";
	private const bool DefaultConsoleVisible = false;
	private static readonly Vector3 ConsoleSpawnPosition = new(0.25f, 1.5f, -1.6f);
	private static readonly Vector3 ConsoleSpawnRotation = new(0f, Mathf.DegToRad(-12f), 0f);

	private GodotObject? _keyboardTrackingExtension;
	private bool _keyboardTrackingAvailable;
	private bool _keyboardPassthroughEnabled;
	private bool _loggedMissingKeyboardSupport;
	private WorkspaceStateService? _workspaceService;
	private FrameOrchestrationService? _frameService;
	private DataBindingService? _bindingService;
	private ConsoleRoot? _consoleRoot;
	private XRController3D? _leftController;
	private XRController3D? _rightController;
	private bool _consoleToggleHeld;
	private bool _frameMoveHeld;
	private string _activeMoveFrameId = "";
	private XRController3D? _activeMoveController;
	private Vector3 _moveOffsetLocal = Vector3.Zero;
	private float _moveHoldDistance = 1.6f;
	private bool _placementGripHeld;
	private Node3D? _placementPreviewRoot;
	private MeshInstance3D? _placementPreviewMesh;
	private Vector2 _placementPreviewSize = Vector2.Zero;
	private Vector3 _placementPreviewGlobal = Vector3.Zero;
	private Vector3 _placementPreviewLocal = Vector3.Zero;
	private Vector3 _placementPreviewRotation = Vector3.Zero;
	private const float PlacementDefaultDistance = 1.9f;
	private const float PlacementMinDistance = 0.75f;
	private const float PlacementMaxDistance = 4.25f;
 	private const float PlacementHeight = 1.0f;

	public override void _Ready()
	{
		EnsureConsoleAction();
		SetupWorkspaceAndConsole();
		ResolveControllers();

		var openxr = XRServer.FindInterface("OpenXR");
		if (openxr != null && openxr.Initialize())
		{
			DisplayServer.WindowSetVsyncMode(DisplayServer.VSyncMode.Disabled);
			GetViewport().UseXR = true;
			GD.Print("OpenXR initialised — headset active.");
		}
		else
		{
			GD.PushWarning("OpenXR not available — headset not connected or runtime not set. See README for VR Quickstart.");
			// Fall back to a desktop camera so the window is not a blank white screen.
			var cam = new Camera3D
			{
				Transform = new Transform3D(Basis.Identity, new Vector3(0f, 1.7f, 5f)),
			};
			GetNode("XROrigin3D").AddChild(cam);
			cam.MakeCurrent();
		}

		SetupKeyboardPassthrough();
		CallDeferred(MethodName.SetupDesktopCapture);
	}

	public override void _Process(double delta)
	{
		HandleControllerConsoleToggle();
		HandleChartPlacementMode();
		HandleFrameMoveMode();
	}

	private void HandleChartPlacementMode()
	{
		if (!GetViewport().UseXR || _frameService == null)
			return;

		if (_rightController == null)
			ResolveControllers();

		if (!_frameService.IsChartPlacementActive())
		{
			_placementGripHeld = false;
			if (_placementPreviewRoot != null)
				_placementPreviewRoot.Visible = false;
			return;
		}

		UpdatePlacementPreviewTransform();

		var gripPressed = _rightController != null && _rightController.IsButtonPressed("grip_click");
		if (gripPressed)
		{
			_placementGripHeld = true;
			return;
		}

		if (_placementGripHeld)
		{
			_placementGripHeld = false;
			var chartType = _frameService.GetPlacementChartType();
			var sizePreset = _frameService.GetPlacementSizePreset();
			var frameId = _frameService.CreateFrameAndReturnId(chartType, sizePreset);
			if (!string.IsNullOrWhiteSpace(frameId) && _frameService.TryGetFrame(frameId, out var placedFrame))
			{
				var targetLocal = placedFrame.Position;
				if (placedFrame.GetParent() is Node3D parent)
					targetLocal = parent.ToLocal(_placementPreviewGlobal);
				_frameService.SetFrameTransform(frameId, targetLocal, _placementPreviewRotation, persist: true);
			}

			_frameService.CancelChartPlacement();
		}
	}

	private void UpdatePlacementPreviewTransform()
	{
		if (_rightController == null || _frameService == null)
			return;

		EnsurePlacementPreviewNode();
		if (_placementPreviewRoot == null)
			return;

		var sizePreset = _frameService.GetPlacementSizePreset();
		var previewSize = FrameOrchestrationService.GetFrameSizeForPreset(sizePreset);
		if (_placementPreviewMesh != null && !_placementPreviewSize.IsEqualApprox(previewSize))
		{
			_placementPreviewMesh.Mesh = BuildPlacementPreviewMesh(previewSize, 0.08f);
			_placementPreviewSize = previewSize;
		}

		var forward = -_rightController.GlobalBasis.Z;
		var planarForward = new Vector3(forward.X, 0f, forward.Z);
		if (planarForward.LengthSquared() < 0.0001f)
			planarForward = Vector3.Forward;
		else
			planarForward = planarForward.Normalized();

		var distance = ComputePlacementDistance(planarForward);
		var previewGlobal = _rightController.GlobalPosition + planarForward * distance;
		previewGlobal.Y = PlacementHeight;
		var yaw = Mathf.RadToDeg(Mathf.Atan2(-planarForward.X, -planarForward.Z));

		_placementPreviewGlobal = previewGlobal;
		_placementPreviewLocal = previewGlobal;
		_placementPreviewRotation = new Vector3(0f, yaw, 0f);
		if (_placementPreviewRoot.GetParent() is Node3D parent)
			_placementPreviewLocal = parent.ToLocal(previewGlobal);

		_placementPreviewRoot.Position = _placementPreviewLocal;
		_placementPreviewRoot.RotationDegrees = _placementPreviewRotation;
		_placementPreviewRoot.Visible = true;
	}

	private float ComputePlacementDistance(Vector3 planarForward)
	{
		if (_rightController == null)
			return PlacementDefaultDistance;

		var world = GetWorld3D();
		if (world == null)
			return PlacementDefaultDistance;

		var from = _rightController.GlobalPosition + new Vector3(0f, 0.05f, 0f);
		var to = from + planarForward * PlacementMaxDistance;
		var query = PhysicsRayQueryParameters3D.Create(from, to);
		query.CollideWithBodies = true;
		query.CollideWithAreas = true;
		query.Exclude = BuildPlacementRayExcludeList();
		var hit = world.DirectSpaceState.IntersectRay(query);
		if (hit.Count == 0 || !hit.ContainsKey("position"))
			return PlacementDefaultDistance;

		var hitPos = hit["position"].AsVector3();
		var distance = from.DistanceTo(hitPos);
		if (!float.IsFinite(distance))
			return PlacementDefaultDistance;

		return Mathf.Clamp(distance - 0.08f, PlacementMinDistance, PlacementMaxDistance);
	}

	private Godot.Collections.Array<Rid> BuildPlacementRayExcludeList()
	{
		var exclude = new Godot.Collections.Array<Rid>();

		AppendCollisionObjectRids(this, exclude);
		AppendCollisionObjectRids(GetNodeOrNull<Node3D>("XROrigin3D"), exclude);
		AppendCollisionObjectRids(_leftController, exclude);
		AppendCollisionObjectRids(_rightController, exclude);

		return exclude;
	}

	private static void AppendCollisionObjectRids(Node? root, Godot.Collections.Array<Rid> exclude)
	{
		if (root == null)
			return;

		if (root is CollisionObject3D collisionObject)
		{
			var rid = collisionObject.GetRid();
			if (rid.IsValid)
				exclude.Add(rid);
		}

		foreach (Node child in root.GetChildren())
			AppendCollisionObjectRids(child, exclude);
	}

	private void EnsurePlacementPreviewNode()
	{
		if (_placementPreviewRoot != null)
			return;

		_placementPreviewRoot = new Node3D
		{
			Name = "PlacementPreview",
			Visible = false,
		};
		AddChild(_placementPreviewRoot);

		_placementPreviewMesh = new MeshInstance3D
		{
			Name = "Wireframe",
			CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
			Mesh = BuildPlacementPreviewMesh(new Vector2(2.2f, 1.4f), 0.08f),
		};

		var material = new StandardMaterial3D
		{
			ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
			Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
			AlbedoColor = new Color(0.2f, 0.9f, 1.0f, 0.75f),
			CullMode = BaseMaterial3D.CullModeEnum.Disabled,
		};
		_placementPreviewMesh.MaterialOverride = material;
		_placementPreviewRoot.AddChild(_placementPreviewMesh);
	}

	private static Mesh BuildPlacementPreviewMesh(Vector2 size, float depth)
	{
		var hx = size.X * 0.5f;
		var hy = size.Y * 0.5f;
		var hz = depth * 0.5f;
		var points = new Vector3[]
		{
			new(-hx, -hy, -hz),
			new(hx, -hy, -hz),
			new(hx, hy, -hz),
			new(-hx, hy, -hz),
			new(-hx, -hy, hz),
			new(hx, -hy, hz),
			new(hx, hy, hz),
			new(-hx, hy, hz),
		};

		var edges = new int[]
		{
			0, 1, 1, 2, 2, 3, 3, 0,
			4, 5, 5, 6, 6, 7, 7, 4,
			0, 4, 1, 5, 2, 6, 3, 7,
		};

		var mesh = new ImmediateMesh();
		mesh.SurfaceBegin(Mesh.PrimitiveType.Lines);
		for (var i = 0; i < edges.Length; i++)
			mesh.SurfaceAddVertex(points[edges[i]]);
		mesh.SurfaceEnd();
		return mesh;
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

		var packed = GD.Load<PackedScene>("res://scenes/console_root.tscn");
		_consoleRoot = packed.Instantiate<ConsoleRoot>();
		_consoleRoot.Name = "ConsoleRoot";
		_consoleRoot.PreferXrInteraction = true;
		_consoleRoot.Position = ConsoleSpawnPosition;
		_consoleRoot.Rotation = ConsoleSpawnRotation;
		AddChild(_consoleRoot);
		_consoleRoot.BindWorkspaceService(_workspaceService);
		if (_frameService != null)
			_consoleRoot.BindFrameService(_frameService);
		if (_bindingService != null)
			_consoleRoot.BindBindingService(_bindingService);

		if (_workspaceService.ActiveWorkspaceProfile.TryGetValue("console_visible", out var storedVisible))
			_consoleRoot.SetConsoleVisible(storedVisible.AsBool());
		else
			_consoleRoot.SetConsoleVisible(DefaultConsoleVisible);
	}

	public override void _Input(InputEvent @event)
	{
		var menuActionExists = InputMap.HasAction(KeyboardPassthroughToggleAction);
		var menuPressed = menuActionExists && @event.IsActionPressed(KeyboardPassthroughToggleAction);

		if (@event.IsActionPressed(ToggleConsoleAction))
		{
			ToggleConsoleAndPersist();
			GetViewport().SetInputAsHandled();
			return;
		}

		if (!_keyboardTrackingAvailable)
		{
			if (menuPressed && !_loggedMissingKeyboardSupport)
			{
				_loggedMissingKeyboardSupport = true;
				GD.PushWarning("Keyboard passthrough is unavailable. Ensure godot-openxr-vendors is installed with binaries and that the active OpenXR runtime supports XR_FB_keyboard_tracking.");
			}
			return;
		}

		if (!menuPressed)
			return;

		SetKeyboardPassthrough(!_keyboardPassthroughEnabled);
	}

	private void SetupKeyboardPassthrough()
	{
		if (!GetViewport().UseXR)
			return;

		if (!ClassDB.ClassExists("XRFbKeyboardTrackingExtension"))
		{
			if (ClassDB.ClassExists("OpenXRFbPassthroughExtension"))
			{
				GD.PushWarning("Keyboard tracking wrapper class (XRFbKeyboardTrackingExtension) is unavailable in the current godot-openxr-vendors build. Full passthrough may be supported, but keyboard-window passthrough is not exposed by this plugin version.");
			}
			else
			{
				GD.PushWarning("XRFbKeyboardTrackingExtension class not found. Install/enable godot-openxr-vendors in the demo project to use keyboard passthrough.");
			}
			return;
		}

		Variant keyboardExtVariant = ClassDB.Instantiate("XRFbKeyboardTrackingExtension");
		if (keyboardExtVariant.VariantType != Variant.Type.Object)
			return;

		_keyboardTrackingExtension = keyboardExtVariant.AsGodotObject();
		if (_keyboardTrackingExtension == null)
			return;

		_keyboardTrackingAvailable = _keyboardTrackingExtension.HasMethod("start_keyboard_tracking")
			&& _keyboardTrackingExtension.HasMethod("stop_keyboard_tracking");
		if (!_keyboardTrackingAvailable)
		{
			GD.PushWarning("XRFbKeyboardTrackingExtension is present but missing start/stop methods in this build.");
			return;
		}

		if (_keyboardTrackingExtension.HasMethod("set_enabled"))
			_keyboardTrackingExtension.Call("set_enabled", true);

		SetKeyboardPassthrough(true);
	}

	private void SetKeyboardPassthrough(bool enabled)
	{
		if (!_keyboardTrackingAvailable || _keyboardTrackingExtension == null)
			return;

		if (enabled)
		{
			var startResult = _keyboardTrackingExtension.Call("start_keyboard_tracking");
			if (startResult.VariantType == Variant.Type.Bool && !startResult.AsBool())
			{
				GD.PushWarning("Keyboard passthrough start request was rejected by the active runtime. This is expected on non-Meta runtimes.");
				_keyboardPassthroughEnabled = false;
				return;
			}

			_keyboardPassthroughEnabled = true;
			GD.Print("Keyboard passthrough window enabled.");
			return;
		}

		var stopResult = _keyboardTrackingExtension.Call("stop_keyboard_tracking");
		if (stopResult.VariantType == Variant.Type.Bool && !stopResult.AsBool())
			GD.PushWarning("Keyboard passthrough stop request was rejected by the active runtime.");

		_keyboardPassthroughEnabled = false;
		GD.Print("Keyboard passthrough window disabled.");
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
		else
		{
			GD.Print("No window selected for capture — using monitor index 0.");
		}

		tex.Set("enabled", true);
	}

	private void ResolveControllers()
	{
		_leftController = GetNodeOrNull<XRController3D>("XROrigin3D/LeftHand");
		_rightController = GetNodeOrNull<XRController3D>("XROrigin3D/RightHand");
	}

	private void HandleControllerConsoleToggle()
	{
		if (!GetViewport().UseXR)
			return;

		if (_leftController == null && _rightController == null)
			ResolveControllers();

		var pressed = IsConsoleToggleButtonPressed();
		if (pressed && !_consoleToggleHeld)
			ToggleConsoleAndPersist();

		_consoleToggleHeld = pressed;
	}

	private void HandleFrameMoveMode()
	{
		if (!GetViewport().UseXR || _frameService == null)
			return;

		if (_frameService.IsChartPlacementActive())
		{
			_frameMoveHeld = false;
			_activeMoveFrameId = "";
			_activeMoveController = null;
			return;
		}

		var moveFrameId = _frameService.GetMoveModeFrameId();
		if (string.IsNullOrWhiteSpace(moveFrameId))
		{
			_frameMoveHeld = false;
			_activeMoveFrameId = "";
			_activeMoveController = null;
			return;
		}

		if (!_frameService.TryGetFrame(moveFrameId, out var frame))
			return;

		var pressed = IsMoveButtonPressed(out var controller);
		if (pressed)
		{
			if (!_frameMoveHeld)
			{
				_frameMoveHeld = true;
				_activeMoveFrameId = moveFrameId;
				_activeMoveController = controller;
				if (_activeMoveController != null)
				{
					_moveOffsetLocal = _activeMoveController.ToLocal(frame.GlobalPosition);
					_moveHoldDistance = Mathf.Clamp(frame.GlobalPosition.DistanceTo(_activeMoveController.GlobalPosition), 0.9f, 3.5f);
				}
			}

			if (_activeMoveController != null && _activeMoveFrameId == moveFrameId)
			{
				var targetPos = _activeMoveController.ToGlobal(_moveOffsetLocal);
				if (!targetPos.IsFinite())
					targetPos = _activeMoveController.GlobalPosition + (-_activeMoveController.GlobalBasis.Z) * _moveHoldDistance;

				var targetLocal = frame.Position;
				if (frame.GetParent() is Node3D parent)
					targetLocal = parent.ToLocal(targetPos);

				var yaw = Mathf.RadToDeg(Mathf.Atan2(-_activeMoveController.GlobalBasis.Z.X, -_activeMoveController.GlobalBasis.Z.Z));
				var rot = frame.RotationDegrees;
				rot.Y = yaw;
				_frameService.SetFrameTransform(moveFrameId, targetLocal, rot, persist: false);
			}
			return;
		}

		if (_frameMoveHeld && _activeMoveFrameId == moveFrameId)
		{
			_frameMoveHeld = false;
			_activeMoveController = null;
			_activeMoveFrameId = "";
			_frameService.SetFrameTransform(moveFrameId, frame.Position, frame.RotationDegrees, persist: true);
		}
	}

	private bool IsConsoleToggleButtonPressed()
	{
		var leftPressed = _leftController != null && _leftController.IsButtonPressed(ConsoleToggleButtonAction);
		var rightPressed = _rightController != null && _rightController.IsButtonPressed(ConsoleToggleButtonAction);
		return leftPressed || rightPressed;
	}

	private bool IsMoveButtonPressed(out XRController3D? controller)
	{
		controller = null;
		if (_leftController != null && _leftController.IsButtonPressed("grip_click"))
		{
			controller = _leftController;
			return true;
		}

		if (_rightController != null && _rightController.IsButtonPressed("grip_click"))
		{
			controller = _rightController;
			return true;
		}

		return false;
	}

	private void ToggleConsoleAndPersist()
	{
		if (_consoleRoot != null)
			_consoleRoot.ToggleConsole();
		if (_workspaceService != null && _consoleRoot != null)
			_workspaceService.SaveActiveWorkspace(_consoleRoot.IsConsoleVisible);
	}
}
