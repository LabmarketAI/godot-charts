using System;
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// Base class for all 3D charts in the Godot Charts addon.
///
/// Provides shared properties (title, axis labels, color palette) and helper
/// methods used by every concrete chart type. Sub-classes override <see cref="_Rebuild"/>
/// to draw their specific geometry inside <see cref="_container"/>.
/// </summary>
[Tool]
public partial class Chart3D : Node3D
{
    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------

    /// <summary>Emitted after the chart geometry has been rebuilt.</summary>
    [Signal]
    public delegate void DataChangedEventHandler();

    /// <summary>
    /// Emitted for every PackedScene instance after it is added to the scene tree.
    /// <paramref name="meshInstance"/> is the instantiated root Node3D.
    /// <paramref name="animationPlayer"/> is the first AnimationPlayer found in its subtree,
    /// or null when none exists.
    /// </summary>
    [Signal]
    public delegate void MeshSpawnedEventHandler(Node3D meshInstance, AnimationPlayer animationPlayer);

    // -------------------------------------------------------------------------
    // Exported properties
    // -------------------------------------------------------------------------

    private string _title = "";
    [Export]
    public string Title
    {
        get => _title;
        set { _title = value; QueueRebuild(); }
    }

    private string _xLabel = "X";
    [Export]
    public string XLabel
    {
        get => _xLabel;
        set { _xLabel = value; QueueRebuild(); }
    }

    private string _yLabel = "Y";
    [Export]
    public string YLabel
    {
        get => _yLabel;
        set { _yLabel = value; QueueRebuild(); }
    }

    private string _zLabel = "Z";
    [Export]
    public string ZLabel
    {
        get => _zLabel;
        set { _zLabel = value; QueueRebuild(); }
    }

    private Vector2 _chartSize = new(4.0f, 3.0f);
    [Export]
    public Vector2 ChartSize
    {
        get => _chartSize;
        set { _chartSize = new Vector2(MathF.Max(value.X, 0.01f), MathF.Max(value.Y, 0.01f)); QueueRebuild(); }
    }

    private Color[] _colors = new[]
    {
        new Color(0.204f, 0.596f, 1.000f),  // blue
        new Color(1.000f, 0.408f, 0.216f),  // orange
        new Color(0.216f, 0.784f, 0.408f),  // green
        new Color(0.988f, 0.729f, 0.012f),  // yellow
        new Color(0.608f, 0.243f, 0.906f),  // purple
        new Color(0.976f, 0.341f, 0.573f),  // pink
    };
    [Export]
    public Color[] Colors
    {
        get => _colors;
        set { _colors = value; QueueRebuild(); }
    }

    private bool _showAxes = true;
    [Export]
    public bool ShowAxes
    {
        get => _showAxes;
        set { _showAxes = value; QueueRebuild(); }
    }

    private bool _showLabels = true;
    [Export]
    public bool ShowLabels
    {
        get => _showLabels;
        set { _showLabels = value; QueueRebuild(); }
    }

    private bool _showGrid;
    [Export]
    public bool ShowGrid
    {
        get => _showGrid;
        set { _showGrid = value; QueueRebuild(); }
    }

    private bool _showTicks = true;
    [Export]
    public bool ShowTicks
    {
        get => _showTicks;
        set { _showTicks = value; QueueRebuild(); }
    }

    private int _tickCount = 5;
    [Export(PropertyHint.Range, "2,20,1")]
    public int TickCount
    {
        get => _tickCount;
        set { _tickCount = value; QueueRebuild(); }
    }

    private bool _showLegend = true;
    [Export]
    public bool ShowLegend
    {
        get => _showLegend;
        set { _showLegend = value; QueueRebuild(); }
    }

    // Materials group
    private Material? _axisMaterial;
    [Export]
    public Material? AxisMaterial
    {
        get => _axisMaterial;
        set { _axisMaterial = value; QueueRebuild(); }
    }

    private Material? _gridMaterial;
    [Export]
    public Material? GridMaterial
    {
        get => _gridMaterial;
        set { _gridMaterial = value; QueueRebuild(); }
    }

    private Material? _tickMaterial;
    [Export]
    public Material? TickMaterial
    {
        get => _tickMaterial;
        set { _tickMaterial = value; QueueRebuild(); }
    }

    private Material? _labelMaterial;
    [Export]
    public Material? LabelMaterial
    {
        get => _labelMaterial;
        set { _labelMaterial = value; QueueRebuild(); }
    }

    private Material? _legendMaterial;
    [Export]
    public Material? LegendMaterial
    {
        get => _legendMaterial;
        set { _legendMaterial = value; QueueRebuild(); }
    }

    // Animation group
    private StringName _spawnAnimation = "";
    [Export]
    public StringName SpawnAnimation
    {
        get => _spawnAnimation;
        set { _spawnAnimation = value; QueueRebuild(); }
    }

    private bool _loopAnimation;
    [Export]
    public bool LoopAnimation
    {
        get => _loopAnimation;
        set { _loopAnimation = value; QueueRebuild(); }
    }

    // Data source group
    private ChartDataSource? _dataSource;
    [Export]
    public ChartDataSource? DataSource
    {
        get => _dataSource;
        set
        {
            if (_dataSource != null && _dataSource.IsConnected(
                    ChartDataSource.SignalName.DataUpdated, Callable.From<Dictionary>(OnDataSourceUpdated)))
                _dataSource.Disconnect(ChartDataSource.SignalName.DataUpdated,
                    Callable.From<Dictionary>(OnDataSourceUpdated));

            _dataSource = value;

            if (_dataSource != null && !_dataSource.IsConnected(
                    ChartDataSource.SignalName.DataUpdated, Callable.From<Dictionary>(OnDataSourceUpdated)))
                _dataSource.Connect(ChartDataSource.SignalName.DataUpdated,
                    Callable.From<Dictionary>(OnDataSourceUpdated));

            QueueRebuild();
        }
    }

    // -------------------------------------------------------------------------
    // Internal state
    // -------------------------------------------------------------------------

    /// <summary>Root node that holds all generated geometry. Cleared on every rebuild.</summary>
    protected Node3D? _container;
    private bool _rebuildQueued;

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    public override void _Ready()
    {
        _container = GetNodeOrNull<Node3D>("ChartContent");
        if (_container == null || !IsInstanceValid(_container))
        {
            _container = new Node3D { Name = "ChartContent" };
            AddChild(_container);
        }

        if (_dataSource != null && !_dataSource.IsConnected(
                ChartDataSource.SignalName.DataUpdated, Callable.From<Dictionary>(OnDataSourceUpdated)))
            _dataSource.Connect(ChartDataSource.SignalName.DataUpdated,
                Callable.From<Dictionary>(OnDataSourceUpdated));

        _Rebuild();
    }

    public override void _Process(double delta)
    {
        if (_rebuildQueued)
        {
            _rebuildQueued = false;
            _Rebuild();
        }
    }

    // -------------------------------------------------------------------------
    // Overridable API
    // -------------------------------------------------------------------------

    /// <summary>Queue a deferred rebuild so rapid property changes only trigger one redraw.</summary>
    protected void QueueRebuild() => _rebuildQueued = true;

    /// <summary>Override in sub-classes to emit geometry into <see cref="_container"/>.</summary>
    protected virtual void _Rebuild() { }

    private void OnDataSourceUpdated(Dictionary _newData) => QueueRebuild();

    /// <summary>
    /// Returns <see cref="ChartDataSource.GetData"/> when a data source is assigned,
    /// otherwise returns an empty Dictionary.
    /// </summary>
    protected Dictionary GetSourceData() => _dataSource?.GetData() ?? new Dictionary();

    // -------------------------------------------------------------------------
    // Public helpers
    // -------------------------------------------------------------------------

    /// <summary>
    /// Remove all children from the chart container immediately.
    /// Uses <c>Free()</c> rather than <c>QueueFree()</c> so geometry is gone before
    /// the next <c>AddChild()</c> call in the same rebuild pass.
    /// </summary>
    public void Clear()
    {
        if (_container != null && IsInstanceValid(_container))
            foreach (var child in _container.GetChildren())
                child.Free();
    }

    // -------------------------------------------------------------------------
    // Protected helpers available to sub-classes
    // -------------------------------------------------------------------------

    /// <summary>Returns the color for the given zero-based dataset index (wraps around).</summary>
    protected Color GetColor(int index)
    {
        if (_colors.Length == 0) return Godot.Colors.White;
        return _colors[index % _colors.Length];
    }

    /// <summary>Creates a simple lit StandardMaterial3D with the given albedo color.</summary>
    protected static Material CreateMaterial(Color color, Material? overrideMat = null)
    {
        if (overrideMat != null) return overrideMat;
        var mat = new StandardMaterial3D { AlbedoColor = color };
        return mat;
    }

    /// <summary>Creates a lit StandardMaterial3D with an optional texture.</summary>
    protected static Material CreateMaterialWithTexture(Color color, Texture2D? texture, Material? overrideMat = null)
    {
        if (overrideMat != null) return overrideMat;
        var mat = new StandardMaterial3D { AlbedoColor = color };
        if (texture != null) mat.AlbedoTexture = texture;
        return mat;
    }

    /// <summary>Creates an unshaded StandardMaterial3D — good for axis lines and wireframes.</summary>
    protected static StandardMaterial3D CreateUnshadedMaterial(Color color)
        => new() { AlbedoColor = color, ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded };

    /// <summary>Creates a billboard Label3D at <paramref name="pos"/> with the given text.</summary>
    protected Label3D MakeLabel(string text, Vector3 pos, int fontSize = 56)
    {
        var lbl = new Label3D
        {
            Text = text,
            Position = pos,
            FontSize = fontSize,
            Billboard = BaseMaterial3D.BillboardModeEnum.Enabled,
            NoDepthTest = true,
            Modulate = new Color(0.9f, 0.9f, 0.9f),
        };
        if (_labelMaterial != null) lbl.MaterialOverride = _labelMaterial;
        return lbl;
    }

    /// <summary>Draws a single line segment using ImmediateMesh.</summary>
    protected static MeshInstance3D MakeLine(Vector3 p0, Vector3 p1, Color color, Material? matOverride = null)
    {
        var mat = matOverride ?? CreateUnshadedMaterial(color);
        var mesh = new ImmediateMesh();
        mesh.SurfaceBegin(Mesh.PrimitiveType.Lines, mat);
        mesh.SurfaceAddVertex(p0);
        mesh.SurfaceAddVertex(p1);
        mesh.SurfaceEnd();
        return new MeshInstance3D
        {
            Mesh = mesh,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
        };
    }

    /// <summary>Draws the three axis lines from the origin with optional labels and title.</summary>
    protected void DrawAxes(float extentX, float extentY, float extentZ)
    {
        if (!_showAxes) return;
        var origin = Vector3.Zero;
        _container!.AddChild(MakeLine(origin, new Vector3(extentX, 0, 0), new Color(0.8f, 0.2f, 0.2f), _axisMaterial));
        _container.AddChild(MakeLine(origin, new Vector3(0, extentY, 0), new Color(0.2f, 0.8f, 0.2f), _axisMaterial));
        _container.AddChild(MakeLine(origin, new Vector3(0, 0, extentZ), new Color(0.2f, 0.5f, 0.9f), _axisMaterial));

        if (!_showLabels) return;
        _container.AddChild(MakeLabel(_xLabel, new Vector3(extentX + 0.15f, 0, 0)));
        _container.AddChild(MakeLabel(_yLabel, new Vector3(0, extentY + 0.15f, 0)));
        _container.AddChild(MakeLabel(_zLabel, new Vector3(0, 0, extentZ + 0.15f)));
        if (!string.IsNullOrEmpty(_title))
            _container.AddChild(MakeLabel(_title, new Vector3(extentX * 0.5f, extentY + 0.35f, 0), 72));
    }

    /// <summary>Draws horizontal gridlines at each Y tick interval across the XY plane.</summary>
    protected void DrawGridXY(float extentX, float extentY)
    {
        if (!_showGrid) return;
        var mat = _gridMaterial ?? CreateUnshadedMaterial(new Color(0.3f, 0.3f, 0.3f));
        for (int i = 1; i <= _tickCount; i++)
        {
            float y = extentY * (i / (float)_tickCount);
            _container!.AddChild(MakeLine(
                new Vector3(0f, y, -0.001f), new Vector3(extentX, y, -0.001f),
                new Color(0.3f, 0.3f, 0.3f), mat));
        }
    }

    /// <summary>Draws tick marks along the Y axis with optional value labels.</summary>
    protected void DrawTicksY(float extentY, float maxVal, float minVal = 0f)
    {
        if (!_showTicks) return;
        var mat = _tickMaterial ?? CreateUnshadedMaterial(new Color(0.55f, 0.55f, 0.55f));
        float tickLen = MathF.Max(_chartSize.X * 0.02f, 0.05f);
        for (int i = 1; i <= _tickCount; i++)
        {
            float t = i / (float)_tickCount;
            float y = extentY * t;
            _container!.AddChild(MakeLine(
                new Vector3(-tickLen, y, 0f), new Vector3(0f, y, 0f),
                new Color(0.55f, 0.55f, 0.55f), mat));
            if (_showLabels)
            {
                float val = minVal + (maxVal - minVal) * t;
                _container.AddChild(MakeLabel($"{val:F1}", new Vector3(-tickLen - 0.18f, y, 0f), 40));
            }
        }
    }

    /// <summary>
    /// Applies <paramref name="mat"/> as <c>MaterialOverride</c> to every MeshInstance3D
    /// found in the subtree rooted at <paramref name="root"/>.
    /// </summary>
    protected static void ApplyMaterialToScene(Node3D root, Material mat)
    {
        if (root is MeshInstance3D mi) mi.MaterialOverride = mat;
        foreach (var child in root.GetChildren())
            if (child is Node3D childNode) ApplyMaterialToScene(childNode, mat);
    }

    /// <summary>
    /// Draws a legend at the right edge of the chart: one colored swatch + name per dataset.
    /// </summary>
    protected void DrawLegend(string[] datasetNames, Color[] legendColors, float extentX, float extentY)
    {
        if (!_showLegend) return;
        const float swatchW = 0.18f, swatchH = 0.11f, rowGap = 0.26f;
        float startX = extentX + 0.25f;
        float startY = extentY * 0.9f;
        for (int i = 0; i < datasetNames.Length; i++)
        {
            float y = startY - i * rowGap;
            var color = i < legendColors.Length ? legendColors[i] : Godot.Colors.White;
            var swatchMat = _legendMaterial ?? CreateMaterial(color);
            var box = new BoxMesh { Size = new Vector3(swatchW, swatchH, 0.05f) };
            var swatchMi = new MeshInstance3D
            {
                Mesh = box,
                MaterialOverride = swatchMat,
                Position = new Vector3(startX + swatchW * 0.5f, y, 0f),
                CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
            };
            _container!.AddChild(swatchMi);
            _container.AddChild(MakeLabel(datasetNames[i], new Vector3(startX + swatchW + 0.15f, y, 0f), 44));
        }
    }

    /// <summary>
    /// Finds the AnimationPlayer in <paramref name="instance"/>, emits <see cref="MeshSpawned"/>,
    /// and plays <see cref="SpawnAnimation"/> if set.
    /// </summary>
    protected void ApplyAnimation(Node3D instance)
    {
        var ap = instance.FindChild("AnimationPlayer", true, false) as AnimationPlayer;
        EmitSignal(SignalName.MeshSpawned, instance, ap!);
        if (ap == null || _spawnAnimation == "") return;
        if (!ap.HasAnimation(_spawnAnimation)) return;
        ap.Play(_spawnAnimation);
        if (!_loopAnimation)
            ap.AnimationFinished += _ => ap.Stop();
    }

    /// <summary>
    /// Builds an ArrayMesh prism with a rounded-rectangle cross-section in the XZ plane,
    /// extruded along the Y axis. Matches BoxMesh centering.
    /// </summary>
    protected static ArrayMesh BuildRoundedBarMesh(float w, float h, float d, float r, int segs = 5)
    {
        r = Math.Clamp(r, 0.001f, MathF.Min(w, d) * 0.5f - 0.001f);
        segs = Math.Max(segs, 1);
        float hw = w * 0.5f, hd = d * 0.5f, hh = h * 0.5f;

        var profile = new System.Collections.Generic.List<Vector2>();
        (float cx, float cz, float sa)[] cornerData =
        {
            ( hw - r,   hd - r,  0f),
            (-(hw-r),   hd - r,  MathF.PI * 0.5f),
            (-(hw-r), -(hd-r),   MathF.PI),
            ( hw - r, -(hd-r),   MathF.PI * 1.5f),
        };
        for (int ci = 0; ci < cornerData.Length; ci++)
        {
            var (cx, cz, sa) = cornerData[ci];
            int first = ci == 0 ? 0 : 1;
            for (int i = first; i <= segs; i++)
            {
                float a = sa + MathF.PI * 0.5f * i / segs;
                profile.Add(new Vector2(cx + MathF.Cos(a) * r, cz + MathF.Sin(a) * r));
            }
        }

        return BuildExtrudedProfile(profile, hh, isXZPlane: true);
    }

    // Shared extrusion builder used by both Chart3D (bar) and ChartFrame3D (panel).
    internal static ArrayMesh BuildExtrudedProfile(
        System.Collections.Generic.List<Vector2> profile, float halfDepth, bool isXZPlane)
    {
        int n = profile.Count;
        var verts = new System.Collections.Generic.List<Vector3>();
        var norms = new System.Collections.Generic.List<Vector3>();
        var indices = new System.Collections.Generic.List<int>();

        if (isXZPlane)
        {
            foreach (var p in profile) verts.Add(new Vector3(p.X, -halfDepth, p.Y));
            foreach (var p in profile) verts.Add(new Vector3(p.X,  halfDepth, p.Y));
        }
        else
        {
            foreach (var p in profile) verts.Add(new Vector3(p.X, p.Y, -halfDepth));
            foreach (var p in profile) verts.Add(new Vector3(p.X, p.Y,  halfDepth));
        }
        verts.Add(isXZPlane ? new Vector3(0f, -halfDepth, 0f) : new Vector3(0f, 0f, -halfDepth));
        verts.Add(isXZPlane ? new Vector3(0f,  halfDepth, 0f) : new Vector3(0f, 0f,  halfDepth));

        for (int i = 0; i < verts.Count; i++)
            norms.Add(Vector3.Zero);
        int bc = n * 2, tc = n * 2 + 1;

        for (int i = 0; i < n; i++)
        {
            int j = (i + 1) % n;
            if (isXZPlane)
            {
                indices.Add(i); indices.Add(j + n); indices.Add(j);
                indices.Add(i); indices.Add(i + n); indices.Add(j + n);
                indices.Add(bc); indices.Add(i); indices.Add(j);
                indices.Add(tc); indices.Add(j + n); indices.Add(i + n);
            }
            else
            {
                indices.Add(i); indices.Add(j); indices.Add(j + n);
                indices.Add(i); indices.Add(j + n); indices.Add(i + n);
                indices.Add(bc); indices.Add(j); indices.Add(i);
                indices.Add(tc); indices.Add(i + n); indices.Add(j + n);
            }
        }

        // Smooth normals via face-normal accumulation
        for (int ti = 0; ti < indices.Count; ti += 3)
        {
            int a = indices[ti], b = indices[ti + 1], c = indices[ti + 2];
            var fn = (verts[b] - verts[a]).Cross(verts[c] - verts[a]);
            norms[a] += fn; norms[b] += fn; norms[c] += fn;
        }
        for (int vi = 0; vi < norms.Count; vi++)
            norms[vi] = norms[vi].Normalized();

        var arrays = new GDArray();
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = verts.ToArray();
        arrays[(int)Mesh.ArrayType.Normal] = norms.ToArray();
        arrays[(int)Mesh.ArrayType.Index]  = indices.ToArray();
        var arrMesh = new ArrayMesh();
        arrMesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);
        return arrMesh;
    }
}
