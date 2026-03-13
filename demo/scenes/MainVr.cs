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
	private const string KeyboardPassthroughToggleAction = "by_button";

	private GodotObject _keyboardTrackingExtension;
	private bool _keyboardTrackingAvailable;
	private bool _keyboardPassthroughEnabled;
	private bool _loggedMissingKeyboardSupport;

	public override void _Ready()
	{
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

	public override void _Input(InputEvent @event)
	{
		if (!_keyboardTrackingAvailable)
		{
			if (@event.IsActionPressed(KeyboardPassthroughToggleAction) && !_loggedMissingKeyboardSupport)
			{
				_loggedMissingKeyboardSupport = true;
				GD.PushWarning("Keyboard passthrough is unavailable. Ensure godot-openxr-vendors is installed with binaries and that the active OpenXR runtime supports XR_FB_keyboard_tracking.");
			}
			return;
		}

		if (!@event.IsActionPressed(KeyboardPassthroughToggleAction))
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
	}
}
