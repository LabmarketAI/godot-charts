using System;
using System.Collections.Generic;
using Godot;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// A movable, resizable 3D panel that hosts <see cref="Chart3D"/> children.
///
/// The frame renders as a thin BoxMesh panel. Any Chart3D added as a direct
/// child is automatically fitted to the frame's inner area and repositioned
/// behind the panel front-face.
/// </summary>
[Tool]
public partial class ChartFrame3D : Node3D
{
    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------

    /// <summary>Emitted after <see cref="Size"/> is changed.</summary>
    [Signal]
    public delegate void ResizedEventHandler(Vector2 newSize);

    // -------------------------------------------------------------------------
    // Exported properties
    // -------------------------------------------------------------------------

    private Vector2 _size = new(4.0f, 3.0f);
    [Export]
    public Vector2 Size
    {
        get => _size;
        set
        {
            _size = new Vector2(MathF.Max(value.X, 0.1f), MathF.Max(value.Y, 0.1f));
            Rebuild();
            EmitSignal(SignalName.Resized, _size);
        }
    }

    private float _frameDepth = 0.1f;
    [Export(PropertyHint.Range, "0.01,1.0,0.005")]
    public float FrameDepth
    {
        get => _frameDepth;
        set { _frameDepth = value; Rebuild(); }
    }

    private Color _backgroundColor = new(0.10f, 0.10f, 0.12f, 1.0f);
    [Export]
    public Color BackgroundColor
    {
        get => _backgroundColor;
        set { _backgroundColor = value; Rebuild(); }
    }

    private Color _borderColor = new(0.45f, 0.45f, 0.50f, 1.0f);
    [Export]
    public Color BorderColor
    {
        get => _borderColor;
        set { _borderColor = value; Rebuild(); }
    }

    private bool _showBackground = true;
    [Export]
    public bool ShowBackground
    {
        get => _showBackground;
        set { _showBackground = value; Rebuild(); }
    }

    private bool _showBorder = true;
    [Export]
    public bool ShowBorder
    {
        get => _showBorder;
        set { _showBorder = value; Rebuild(); }
    }

    private float _padding = 0.15f;
    [Export(PropertyHint.Range, "0.0,1.0,0.01")]
    public float Padding
    {
        get => _padding;
        set { _padding = value; FitChildCharts(); }
    }

    private float _cornerRadius;
    [Export(PropertyHint.Range, "0.0,2.0,0.01")]
    public float CornerRadius
    {
        get => _cornerRadius;
        set { _cornerRadius = value; Rebuild(); }
    }

    // -------------------------------------------------------------------------
    // Internal state
    // -------------------------------------------------------------------------

    private Node3D? _internal;

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    public override void _Ready()
    {
        _internal = GetNodeOrNull<Node3D>("_FrameInternal");
        if (_internal == null || !IsInstanceValid(_internal))
        {
            _internal = new Node3D { Name = "_FrameInternal" };
            AddChild(_internal);
        }
        Rebuild();
    }

    public override void _Notification(int what)
    {
        if (what == NotificationChildOrderChanged && _internal != null && IsInstanceValid(_internal))
            FitChildCharts();
    }

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /// <summary>Programmatically resize the frame. Equivalent to setting <see cref="Size"/>.</summary>
    public void Resize(Vector2 newSize) => Size = newSize;

    /// <summary>Returns the usable inner area after subtracting padding from both sides.</summary>
    public Vector2 GetInnerSize() => new(
        MathF.Max(_size.X - _padding * 2f, 0.01f),
        MathF.Max(_size.Y - _padding * 2f, 0.01f));

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private void Rebuild()
    {
        if (_internal == null || !IsInstanceValid(_internal)) return;
        foreach (var child in _internal.GetChildren()) child.Free();
        BuildPanel();
        FitChildCharts();
    }

    private void BuildPanel()
    {
        if (_showBackground)
        {
            Mesh panelMesh;
            if (_cornerRadius > 0f)
                panelMesh = BuildRoundedPanelMesh(_size.X, _size.Y, _frameDepth, _cornerRadius);
            else
                panelMesh = new BoxMesh { Size = new Vector3(_size.X, _size.Y, _frameDepth) };

            var mat = new StandardMaterial3D { AlbedoColor = _backgroundColor };
            var mi = new MeshInstance3D
            {
                Name = "Background",
                Mesh = panelMesh,
                MaterialOverride = mat,
                Position = new Vector3(_size.X * 0.5f, _size.Y * 0.5f, -_frameDepth * 0.5f),
                CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
            };
            _internal!.AddChild(mi);
        }

        if (_showBorder) BuildBorder();
    }

    private void BuildBorder()
    {
        var mat = new StandardMaterial3D
        {
            AlbedoColor = _borderColor,
            ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
        };
        var mesh = new ImmediateMesh();
        mesh.SurfaceBegin(Mesh.PrimitiveType.Lines, mat);
        float z = 0.001f, cx = _size.X, cy = _size.Y;
        Vector3[] verts =
        {
            new(0,  0,  z), new(cx, 0,  z),
            new(cx, 0,  z), new(cx, cy, z),
            new(cx, cy, z), new(0,  cy, z),
            new(0,  cy, z), new(0,  0,  z),
        };
        foreach (var v in verts) mesh.SurfaceAddVertex(v);
        mesh.SurfaceEnd();
        _internal!.AddChild(new MeshInstance3D
        {
            Name = "Border",
            Mesh = mesh,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
        });
    }

    private void FitChildCharts()
    {
        var inner = GetInnerSize();
        foreach (var child in GetChildren())
        {
            if (child == _internal) continue;
            if (child is Chart3D chart)
            {
                chart.ChartSize = inner;
                chart.Position = new Vector3(_padding, _padding, 0.005f);
            }
        }
    }

    private static ArrayMesh BuildRoundedPanelMesh(float w, float h, float d, float r, int segs = 5)
    {
        r = Math.Clamp(r, 0.001f, MathF.Min(w, h) * 0.5f - 0.001f);
        segs = Math.Max(segs, 1);
        float hw = w * 0.5f, hh = h * 0.5f;

        var profile = new List<Vector2>();
        (float cx, float cy, float sa)[] cornerData =
        {
            ( hw - r,   hh - r,  0f),
            (-(hw-r),   hh - r,  MathF.PI * 0.5f),
            (-(hw-r), -(hh-r),   MathF.PI),
            ( hw - r, -(hh-r),   MathF.PI * 1.5f),
        };
        for (int ci = 0; ci < cornerData.Length; ci++)
        {
            var (cx, cy, sa) = cornerData[ci];
            int first = ci == 0 ? 0 : 1;
            for (int i = first; i <= segs; i++)
            {
                float a = sa + MathF.PI * 0.5f * i / segs;
                profile.Add(new Vector2(cx + MathF.Cos(a) * r, cy + MathF.Sin(a) * r));
            }
        }

        return Chart3D.BuildExtrudedProfile(profile, d * 0.5f, isXZPlane: false);
    }
}
