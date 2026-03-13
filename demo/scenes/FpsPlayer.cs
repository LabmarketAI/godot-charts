// First-person player controller for the desktop data-room demo.
//
// Attach to a CharacterBody3D that has a Camera3D child named "Camera3D"
// and a CollisionShape3D (CapsuleShape3D radius=0.3, height=1.8).
//
// Controls:
//   W/S/↑/↓  — walk forward / back
//   A/D      — strafe left / right
//   Mouse    — look
//   Escape   — toggle mouse capture
using Godot;

public partial class FpsPlayer : CharacterBody3D
{
    private const float Speed            = 5f;
    private const float MouseSensitivity = 0.003f;

    private Camera3D _camera = null!;
    private bool _mouseCaptured;

    public override void _Ready()
    {
        _camera = GetNode<Camera3D>("Camera3D");
        SetMouseCaptured(true);
    }

    private void SetMouseCaptured(bool captured)
    {
        _mouseCaptured = captured;
        Input.MouseMode = captured ? Input.MouseModeEnum.Captured : Input.MouseModeEnum.Visible;
    }

    public override void _Input(InputEvent @event)
    {
        if (@event is InputEventMouseMotion motion && _mouseCaptured)
        {
            RotateY(-motion.Relative.X * MouseSensitivity);
            _camera.RotateX(-motion.Relative.Y * MouseSensitivity);
            _camera.Rotation = _camera.Rotation with
            {
                X = Mathf.Clamp(_camera.Rotation.X, Mathf.DegToRad(-80f), Mathf.DegToRad(80f)),
            };
        }

        if (@event is InputEventKey key && key.Pressed && key.Keycode == Key.Escape)
            SetMouseCaptured(!_mouseCaptured);
    }

    public override void _PhysicsProcess(double delta)
    {
        var vel = Velocity;

        // Gravity.
        if (!IsOnFloor())
            vel.Y -= (float)ProjectSettings.GetSetting("physics/3d/default_gravity", 9.8).AsDouble() * (float)delta;

        // WASD movement — direct key polling avoids needing action-map entries.
        int fw = (Input.IsKeyPressed(Key.W) || Input.IsKeyPressed(Key.Up))   ? 1 : 0;
        int bk = (Input.IsKeyPressed(Key.S) || Input.IsKeyPressed(Key.Down)) ? 1 : 0;
        int lt =  Input.IsKeyPressed(Key.A) ? 1 : 0;
        int rt =  Input.IsKeyPressed(Key.D) ? 1 : 0;

        // inputDir.X = strafe (positive = right), inputDir.Y = forward/back.
        var inputDir  = new Vector2(rt - lt, bk - fw);
        var direction = (Transform.Basis * new Vector3(inputDir.X, 0f, inputDir.Y)).Normalized();

        if (direction != Vector3.Zero)
        {
            vel.X = direction.X * Speed;
            vel.Z = direction.Z * Speed;
        }
        else
        {
            vel.X = Mathf.MoveToward(vel.X, 0f, Speed);
            vel.Z = Mathf.MoveToward(vel.Z, 0f, Speed);
        }

        Velocity = vel;
        MoveAndSlide();
    }

    /// <summary>
    /// Teleport the player to <paramref name="pos"/> and face <paramref name="lookAtPos"/>.
    /// Used by Main._FlyTo when the user presses [1]–[7].
    /// </summary>
    public void TeleportTo(Vector3 pos, Vector3 lookAtPos)
    {
        GlobalPosition = pos;
        Velocity       = Vector3.Zero;
        _camera.Rotation = _camera.Rotation with { X = 0f };
        // Flatten the look target to the player's Y so pitch stays level.
        var flatTarget = new Vector3(lookAtPos.X, GlobalPosition.Y, lookAtPos.Z);
        if (GlobalPosition.DistanceTo(flatTarget) > 0.001f)
            LookAt(flatTarget, Vector3.Up);
    }
}
