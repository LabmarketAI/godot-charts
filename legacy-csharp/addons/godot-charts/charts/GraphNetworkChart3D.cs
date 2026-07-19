using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using GDArray = Godot.Collections.Array;
using GDDict = Godot.Collections.Dictionary;
using QuikGraph;
using MsaglGeometry = Microsoft.Msagl.Core.Layout;
using MsaglCurves   = Microsoft.Msagl.Core.Geometry.Curves;
using Microsoft.Msagl.Layout.Layered;
using Microsoft.Msagl.Layout.Incremental;
using Microsoft.Msagl.Miscellaneous;

namespace GodotCharts;

/// <summary>
/// A 3D graph network chart rendered in full XYZ space.
///
/// Nodes and edges are sourced from a NetworkX-compatible node_link_data JSON dict
/// supplied via <see cref="ChartDataSource"/> or the inline <see cref="Data"/> property.
///
/// <b>Layout modes</b>
/// <list type="bullet">
/// <item><term>Preset</term><description>Read x/y/z directly from node data.</description></item>
/// <item><term>Circular</term><description>Fibonacci-sphere distribution.</description></item>
/// <item><term>Spring</term><description>MSAGL FastIncremental force-directed (XY plane).</description></item>
/// <item><term>Hierarchical</term><description>MSAGL Sugiyama layered (XY plane).</description></item>
/// </list>
///
/// Internally the graph is represented with <b>QuikGraph</b>
/// (<see cref="BidirectionalGraph{TVertex,TEdge}"/>) and layouts are computed with
/// <b>MSAGL</b> (FastIncrementalLayout / SugiyamaLayoutSettings).
/// </summary>
[Tool]
public partial class GraphNetworkChart3D : Chart3D
{
    // -------------------------------------------------------------------------
    // Layout mode enum
    // -------------------------------------------------------------------------

    public enum LayoutMode
    {
        /// <summary>Use preset x/y/z coordinates from the data.</summary>
        Preset      = 0,
        /// <summary>Distribute nodes on a Fibonacci sphere.</summary>
        Circular    = 1,
        /// <summary>MSAGL FastIncremental force-directed layout (XY plane).</summary>
        Spring      = 2,
        /// <summary>MSAGL Sugiyama hierarchical layout (XY plane).</summary>
        Hierarchical = 3,
    }

    // -------------------------------------------------------------------------
    // Default meshes
    // -------------------------------------------------------------------------

    private static readonly Mesh DefaultNodeMesh =
        GD.Load<Mesh>("res://addons/godot-charts/assets/meshes/node_sphere.tres");
    private static readonly Mesh DefaultArrowHead =
        GD.Load<Mesh>("res://addons/godot-charts/assets/meshes/arrow_head.tres");

    // -------------------------------------------------------------------------
    // Exported properties
    // -------------------------------------------------------------------------

    private GDDict _data = new();
    [Export]
    public GDDict Data
    {
        get => _data;
        set { _data = value; QueueRebuild(); }
    }

    private LayoutMode _layoutMode = LayoutMode.Preset;
    [Export]
    public LayoutMode Layout
    {
        get => _layoutMode;
        set { _layoutMode = value; QueueRebuild(); }
    }

    private float _nodeRadius = 0.15f;
    [Export(PropertyHint.Range, "0.05,1.0,0.005")]
    public float NodeRadius
    {
        get => _nodeRadius;
        set { _nodeRadius = value; QueueRebuild(); }
    }

    private float _edgeWidth = 0.02f;
    [Export(PropertyHint.Range, "0.005,0.5,0.005")]
    public float EdgeWidth
    {
        get => _edgeWidth;
        set { _edgeWidth = value; QueueRebuild(); }
    }

    private float _edgeRadius;
    [Export(PropertyHint.Range, "0.0,0.2,0.005")]
    public float EdgeRadius
    {
        get => _edgeRadius;
        set { _edgeRadius = value; QueueRebuild(); }
    }

    private float _edgeWeightScale = 1f;
    [Export(PropertyHint.Range, "0.0,2.0,0.01")]
    public float EdgeWeightScale
    {
        get => _edgeWeightScale;
        set { _edgeWeightScale = value; QueueRebuild(); }
    }

    private bool _showNodeLabels = true;
    [Export]
    public bool ShowNodeLabels
    {
        get => _showNodeLabels;
        set { _showNodeLabels = value; QueueRebuild(); }
    }

    private bool _showEdgeLabels;
    [Export]
    public bool ShowEdgeLabels
    {
        get => _showEdgeLabels;
        set { _showEdgeLabels = value; QueueRebuild(); }
    }

    private int _springIterations = 50;
    [Export(PropertyHint.Range, "10,500,10")]
    public int SpringIterations
    {
        get => _springIterations;
        set { _springIterations = value; QueueRebuild(); }
    }

    // Type override exports
    private GDDict _nodeTypeScenes = new();
    [Export] public GDDict NodeTypeScenes
    { get => _nodeTypeScenes; set { _nodeTypeScenes = value; QueueRebuild(); } }

    private GDDict _nodeTypeMaterials = new();
    [Export] public GDDict NodeTypeMaterials
    { get => _nodeTypeMaterials; set { _nodeTypeMaterials = value; QueueRebuild(); } }

    private GDDict _nodeTypeMeshes = new();
    [Export] public GDDict NodeTypeMeshes
    { get => _nodeTypeMeshes; set { _nodeTypeMeshes = value; QueueRebuild(); } }

    private Mesh? _nodeDefaultMesh;
    [Export] public Mesh? NodeDefaultMesh
    { get => _nodeDefaultMesh; set { _nodeDefaultMesh = value; QueueRebuild(); } }

    private GDDict _nodeTypeTextures = new();
    [Export] public GDDict NodeTypeTextures
    { get => _nodeTypeTextures; set { _nodeTypeTextures = value; QueueRebuild(); } }

    private Texture2D? _nodeDefaultTexture;
    [Export] public Texture2D? NodeDefaultTexture
    { get => _nodeDefaultTexture; set { _nodeDefaultTexture = value; QueueRebuild(); } }

    private GDDict _edgeTypeMaterials = new();
    [Export] public GDDict EdgeTypeMaterials
    { get => _edgeTypeMaterials; set { _edgeTypeMaterials = value; QueueRebuild(); } }

    private GDDict _edgeTypeTextures = new();
    [Export] public GDDict EdgeTypeTextures
    { get => _edgeTypeTextures; set { _edgeTypeTextures = value; QueueRebuild(); } }

    private Texture2D? _edgeDefaultTexture;
    [Export] public Texture2D? EdgeDefaultTexture
    { get => _edgeDefaultTexture; set { _edgeDefaultTexture = value; QueueRebuild(); } }

    private PackedScene? _edgeMeshScene;
    [Export] public PackedScene? EdgeMeshScene
    { get => _edgeMeshScene; set { _edgeMeshScene = value; QueueRebuild(); } }

    // Per-frame spring
    private bool _springPerFrame;
    [Export]
    public bool SpringPerFrame
    {
        get => _springPerFrame;
        set { _springPerFrame = value; QueueRebuild(); }
    }

    // -------------------------------------------------------------------------
    // Internal state
    // -------------------------------------------------------------------------

    private readonly Dictionary<string, Node3D> _nodeInstances = new();
    private Node3D? _nodeContainer;
    private Node3D? _edgeContainer;
    private Node3D? _labelContainer;
    private readonly Dictionary<string, int> _typeColorIndex = new();

    // Per-frame spring state
    private bool _springRunning;
    private Dictionary<string, Vector3> _springPos = new();
    private List<string> _springIds = new();
    private GDArray _springEdges = new();
    private float _springTemp;
    private int _springStep;

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    public override void _Process(double delta)
    {
        base._Process(delta);

        // Drive file hot-reload on assigned GraphNetworkDataSource
        if (DataSource is GraphNetworkDataSource gnds)
            gnds.Tick();

        if (_springRunning)
            SpringStep3D();
    }

    // -------------------------------------------------------------------------
    // Chart3D override
    // -------------------------------------------------------------------------

    protected override void _Rebuild()
    {
        if (_container == null || !IsInstanceValid(_container)) return;
        EnsureSubContainers();
        _springRunning = false;

        var d = DataSource != null ? GetSourceData() : _data;
        var nodes = d.TryGetValue("nodes", out Variant nv) && nv.Obj is GDArray na ? na : new GDArray();
        var edges = d.TryGetValue("edges", out Variant ev) && ev.Obj is GDArray ea
            ? ea
            : (d.TryGetValue("links", out Variant lv) && lv.Obj is GDArray la ? la : new GDArray());

        if (nodes.Count == 0) { ClearAll(); DrawDemo(); return; }

        Dictionary<string, Vector3> layout;
        if (_layoutMode == LayoutMode.Spring && _springPerFrame)
            layout = StartSpring3D(nodes, edges);
        else
            layout = ComputeLayout(nodes, edges);

        SyncNodes(nodes, layout);

        foreach (var child in _edgeContainer!.GetChildren()) child.Free();
        DrawEdges(edges, layout);

        foreach (var child in _labelContainer!.GetChildren()) child.Free();
        if (_showNodeLabels) DrawNodeLabels(nodes, layout);
        if (_showEdgeLabels) DrawEdgeLabels(edges, layout);

        EmitSignal(SignalName.DataChanged);
    }

    // -------------------------------------------------------------------------
    // Layout computation
    // -------------------------------------------------------------------------

    private Dictionary<string, Vector3> ComputeLayout(GDArray nodes, GDArray edges)
        => _layoutMode switch
        {
            LayoutMode.Circular    => LayoutSphere(nodes),
            LayoutMode.Spring      => LayoutMsaglForce(nodes, edges),
            LayoutMode.Hierarchical => LayoutMsaglHierarchical(nodes, edges),
            _                      => LayoutPreset3D(nodes),
        };

    private Dictionary<string, Vector3> LayoutPreset3D(GDArray nodes)
    {
        var raw = new Dictionary<string, Vector3>();
        foreach (Variant n in nodes)
            if (n.Obj is GDDict nd)
            {
                string id = nd.TryGetValue("id", out Variant iv) ? iv.ToString() : "";
                float x = nd.TryGetValue("x", out Variant xv) ? (float)(double)xv : 0f;
                float y = nd.TryGetValue("y", out Variant yv) ? (float)(double)yv : 0f;
                float z = nd.TryGetValue("z", out Variant zv) ? (float)(double)zv : 0f;
                raw[id] = new Vector3(x, y, z);
            }
        return NormalizeToChart3D(raw);
    }

    private Dictionary<string, Vector3> LayoutSphere(GDArray nodes)
    {
        var result = new Dictionary<string, Vector3>();
        int n = nodes.Count;
        if (n == 0) return result;
        float cx = ChartSize.X * 0.5f, cy = ChartSize.Y * 0.5f;
        float cz = MathF.Min(ChartSize.X, ChartSize.Y) * 0.5f;
        float r  = MathF.Min(ChartSize.X, ChartSize.Y) * 0.38f;
        float ga = MathF.PI * (3f - MathF.Sqrt(5f));
        for (int i = 0; i < n; i++)
        {
            string id = nodes[i].Obj is GDDict nd && nd.TryGetValue("id", out Variant iv)
                ? iv.ToString() : i.ToString();
            float t   = (float)i / MathF.Max(n - 1, 1);
            float inc = MathF.Acos(1f - 2f * t);
            float az  = ga * i;
            result[id] = new Vector3(
                cx + r * MathF.Sin(inc) * MathF.Cos(az),
                cy + r * MathF.Cos(inc),
                cz + r * MathF.Sin(inc) * MathF.Sin(az));
        }
        return result;
    }

    /// <summary>MSAGL FastIncremental force-directed layout (returns XY, Z=0).</summary>
    private Dictionary<string, Vector3> LayoutMsaglForce(GDArray nodes, GDArray edges)
    {
        var (geoGraph, idToNode) = BuildMsaglGraph(nodes, edges);
        var settings = new FastIncrementalLayoutSettings
        {
            MaxIterations = _springIterations,
        };
        LayoutHelpers.CalculateLayout(geoGraph, settings, null);
        return MsaglToLayout(idToNode, nodes);
    }

    /// <summary>MSAGL Sugiyama hierarchical layout (returns XY, Z=0).</summary>
    private Dictionary<string, Vector3> LayoutMsaglHierarchical(GDArray nodes, GDArray edges)
    {
        var (geoGraph, idToNode) = BuildMsaglGraph(nodes, edges);
        var settings = new SugiyamaLayoutSettings();
        LayoutHelpers.CalculateLayout(geoGraph, settings, null);
        return MsaglToLayout(idToNode, nodes);
    }

    private (MsaglGeometry.GeometryGraph graph,
             Dictionary<string, MsaglGeometry.Node> idToNode)
        BuildMsaglGraph(GDArray nodes, GDArray edges)
    {
        var graph    = new MsaglGeometry.GeometryGraph();
        var idToNode = new Dictionary<string, MsaglGeometry.Node>();

        foreach (Variant n in nodes)
            if (n.Obj is GDDict nd)
            {
                string id = nd.TryGetValue("id", out Variant iv) ? iv.ToString() : "";
                var gn = new MsaglGeometry.Node(MsaglCurves.CurveFactory.CreateEllipse(10, 10, new Microsoft.Msagl.Core.Geometry.Point()));
                graph.Nodes.Add(gn);
                idToNode[id] = gn;
            }

        foreach (Variant e in edges)
            if (e.Obj is GDDict ed)
            {
                string src = ed.TryGetValue("source", out Variant sv) ? sv.ToString() : "";
                string tgt = ed.TryGetValue("target", out Variant tv) ? tv.ToString() : "";
                if (idToNode.TryGetValue(src, out var sn) && idToNode.TryGetValue(tgt, out var tn))
                    graph.Edges.Add(new MsaglGeometry.Edge(sn, tn));
            }

        return (graph, idToNode);
    }

    private Dictionary<string, Vector3> MsaglToLayout(
        Dictionary<string, MsaglGeometry.Node> idToNode, GDArray nodes)
    {
        // Read raw MSAGL positions
        var raw = new Dictionary<string, Vector3>();
        foreach (Variant n in nodes)
            if (n.Obj is GDDict nd)
            {
                string id = nd.TryGetValue("id", out Variant iv) ? iv.ToString() : "";
                if (idToNode.TryGetValue(id, out var gn))
                    raw[id] = new Vector3((float)gn.Center.X, (float)gn.Center.Y, 0f);
            }
        return NormalizeToChart3D(raw);
    }

    // -------------------------------------------------------------------------
    // Per-frame spring (Fruchterman-Reingold — used when SpringPerFrame = true)
    // -------------------------------------------------------------------------

    private Dictionary<string, Vector3> StartSpring3D(GDArray nodes, GDArray edges)
    {
        _springEdges = edges;
        _springIds   = new List<string>();
        _springPos   = new Dictionary<string, Vector3>();
        int n = nodes.Count;
        float ga = MathF.PI * (3f - MathF.Sqrt(5f));
        for (int i = 0; i < n; i++)
        {
            string id = nodes[i].Obj is GDDict nd && nd.TryGetValue("id", out Variant iv)
                ? iv.ToString() : i.ToString();
            _springIds.Add(id);
            float t   = (float)i / MathF.Max(n - 1, 1);
            float inc = MathF.Acos(1f - 2f * t);
            float az  = ga * i;
            _springPos[id] = new Vector3(
                0.5f + 0.4f * MathF.Sin(inc) * MathF.Cos(az),
                0.5f + 0.4f * MathF.Cos(inc),
                0.5f + 0.4f * MathF.Sin(inc) * MathF.Sin(az));
        }
        _springTemp = 0.15f; _springStep = 0; _springRunning = true;
        return NormalizeToChart3D(_springPos);
    }

    private void SpringStep3D()
    {
        if (_springStep >= _springIterations) { _springRunning = false; return; }
        float k = MathF.Pow(1f / MathF.Max(_springIds.Count, 1), 1f / 3f);
        var disp = _springIds.ToDictionary(id => id, _ => Vector3.Zero);

        for (int i = 0; i < _springIds.Count; i++)
            for (int j = i + 1; j < _springIds.Count; j++)
            {
                string vi = _springIds[i], vj = _springIds[j];
                var delta = _springPos[vi] - _springPos[vj];
                float dist = MathF.Max(delta.Length(), 0.001f);
                float force = k * k / dist;
                var dn = delta / dist;
                disp[vi] += dn * force; disp[vj] -= dn * force;
            }

        foreach (Variant e in _springEdges)
            if (e.Obj is GDDict ed)
            {
                string src = ed.TryGetValue("source", out Variant sv) ? sv.ToString() : "";
                string tgt = ed.TryGetValue("target", out Variant tv) ? tv.ToString() : "";
                if (!_springPos.ContainsKey(src) || !_springPos.ContainsKey(tgt)) continue;
                var delta = _springPos[tgt] - _springPos[src];
                float dist = MathF.Max(delta.Length(), 0.001f);
                float force = dist * dist / k;
                var dn = delta / dist;
                disp[tgt] -= dn * force; disp[src] += dn * force;
            }

        foreach (string id in _springIds)
        {
            var dv = disp[id];
            float dl = MathF.Max(dv.Length(), 0.001f);
            _springPos[id] += dv / dl * MathF.Min(dl, _springTemp);
        }

        _springTemp *= 0.95f; _springStep++;

        var layout = NormalizeToChart3D(_springPos);
        foreach (string id in _springIds)
            if (_nodeInstances.TryGetValue(id, out var inst))
                inst.Position = layout.GetValueOrDefault(id);

        if (_edgeContainer != null && IsInstanceValid(_edgeContainer))
        {
            foreach (var child in _edgeContainer.GetChildren()) child.Free();
            DrawEdges(_springEdges, layout);
        }
    }

    // -------------------------------------------------------------------------
    // Node sync
    // -------------------------------------------------------------------------

    private void SyncNodes(GDArray nodes, Dictionary<string, Vector3> layout)
    {
        var newIds = new Dictionary<string, GDDict>();
        foreach (Variant n in nodes)
            if (n.Obj is GDDict nd)
            {
                string id = nd.TryGetValue("id", out Variant iv) ? iv.ToString() : "";
                newIds[id] = nd;
            }

        foreach (string id in _nodeInstances.Keys.ToList())
            if (!newIds.ContainsKey(id)) CollapseAndFree(id);

        AssignTypeIndices(nodes);

        foreach (var (id, nd) in newIds)
        {
            var pos = layout.GetValueOrDefault(id);
            if (_nodeInstances.TryGetValue(id, out var existing))
                existing.Position = pos;
            else
            {
                var inst = CreateNodeInstance(nd, pos);
                _nodeContainer!.AddChild(inst);
                _nodeInstances[id] = inst;
                PopIn(inst);
            }
        }
    }

    private Node3D CreateNodeInstance(GDDict n, Vector3 pos)
    {
        string ntype = n.TryGetValue("type", out Variant tv) ? tv.ToString() : "";
        var color = GetTypeColor(ntype);

        if (_nodeTypeScenes.TryGetValue(ntype, out Variant scv) && scv.Obj is PackedScene scene)
        {
            var inst = scene.Instantiate<Node3D>();
            inst.Position = pos; inst.Scale = Vector3.One * _nodeRadius;
            if (_nodeTypeMaterials.TryGetValue(ntype, out Variant mv) && mv.Obj is Material m)
                ApplyMaterialToScene(inst, m);
            ApplyAnimation(inst);
            return inst;
        }

        Material mat;
        if (_nodeTypeMaterials.TryGetValue(ntype, out Variant matv) && matv.Obj is Material typeMat)
            mat = typeMat;
        else
        {
            var tex = GetNodeTexture(ntype);
            mat = CreateMaterialWithTexture(color, tex);
        }

        return new MeshInstance3D
        {
            Mesh             = GetNodeMesh(ntype),
            Scale            = Vector3.One * _nodeRadius,
            MaterialOverride = mat,
            Position         = pos,
            CastShadow       = GeometryInstance3D.ShadowCastingSetting.Off,
        };
    }

    private Mesh GetNodeMesh(string ntype)
    {
        if (_nodeTypeMeshes.TryGetValue(ntype, out Variant mv) && mv.Obj is Mesh m) return m;
        return _nodeDefaultMesh ?? DefaultNodeMesh;
    }

    private Texture2D? GetNodeTexture(string ntype)
    {
        if (_nodeTypeTextures.TryGetValue(ntype, out Variant tv) && tv.Obj is Texture2D t) return t;
        return _nodeDefaultTexture;
    }

    private Texture2D? GetEdgeTexture(string etype)
    {
        if (_edgeTypeTextures.TryGetValue(etype, out Variant tv) && tv.Obj is Texture2D t) return t;
        return _edgeDefaultTexture;
    }

    // -------------------------------------------------------------------------
    // Node animations
    // -------------------------------------------------------------------------

    private void PopIn(Node3D inst)
    {
        var target = inst.Scale;
        inst.Scale = Vector3.Zero;
        var tween = CreateTween();
        tween.TweenProperty(inst, "scale", target, 0.3)
             .SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Back);
    }

    private void CollapseAndFree(string id)
    {
        if (!_nodeInstances.Remove(id, out var inst)) return;
        if (!IsInstanceValid(inst)) return;
        var tween = CreateTween();
        tween.TweenProperty(inst, "scale", Vector3.Zero, 0.25).SetEase(Tween.EaseType.In);
        tween.TweenCallback(Callable.From(inst.QueueFree));
    }

    // -------------------------------------------------------------------------
    // Public animation API
    // -------------------------------------------------------------------------

    public void PopNode(string id)  { if (_nodeInstances.TryGetValue(id, out var inst)) PopIn(inst); }
    public void CollapseNode(string id) => CollapseAndFree(id);

    public void PopAll(float staggerSec = 0.05f)
    {
        int i = 0;
        foreach (var (_, inst) in _nodeInstances)
        {
            var target = Vector3.One * _nodeRadius;
            inst.Scale = Vector3.Zero;
            var tween = CreateTween();
            tween.TweenInterval(staggerSec * i);
            tween.TweenProperty(inst, "scale", target, 0.3)
                 .SetEase(Tween.EaseType.Out).SetTrans(Tween.TransitionType.Back);
            i++;
        }
    }

    public void CollapseAll(float staggerSec = 0.05f)
    {
        int i = 0;
        foreach (var id in _nodeInstances.Keys.ToList())
        {
            if (!_nodeInstances.Remove(id, out var inst) || !IsInstanceValid(inst)) { i++; continue; }
            var tween = CreateTween();
            tween.TweenInterval(staggerSec * i);
            tween.TweenProperty(inst, "scale", Vector3.Zero, 0.25).SetEase(Tween.EaseType.In);
            tween.TweenCallback(Callable.From(inst.QueueFree));
            i++;
        }
    }

    // -------------------------------------------------------------------------
    // Edge drawing
    // -------------------------------------------------------------------------

    private void DrawEdges(GDArray edges, Dictionary<string, Vector3> layout)
    {
        foreach (Variant e in edges)
        {
            if (e.Obj is not GDDict ed) continue;
            string src  = ed.TryGetValue("source", out Variant sv) ? sv.ToString() : "";
            string tgt  = ed.TryGetValue("target", out Variant tv) ? tv.ToString() : "";
            if (!layout.ContainsKey(src) || !layout.ContainsKey(tgt)) continue;

            var v0 = layout[src];
            var v1 = layout[tgt];
            string etype = ed.TryGetValue("type", out Variant etv) ? etv.ToString() : "";
            Material? mat = _edgeTypeMaterials.TryGetValue(etype, out Variant mv) && mv.Obj is Material m ? m : null;

            var tex = GetEdgeTexture(etype);
            if (tex != null)
            {
                var edgeColor = mat == null ? new Color(0.6f, 0.6f, 0.65f) : Godot.Colors.White;
                mat = CreateMaterialWithTexture(edgeColor, tex, mat);
            }
            mat ??= CreateUnshadedMaterial(new Color(0.6f, 0.6f, 0.65f));

            float weight = ed.TryGetValue("weight", out Variant wv) ? (float)Math.Clamp((double)wv, 0.001, 1.0) : 1f;
            float effRadius = _edgeRadius * (_edgeWeightScale == 0f ? 1f : weight * _edgeWeightScale);

            if (_edgeRadius > 0f && _edgeMeshScene == null)
                DrawEdgeCylinder(v0, v1, mat, effRadius);
            else if (_edgeMeshScene != null)
                DrawEdgeScene(v0, v1, mat);
            else
                _edgeContainer!.AddChild(MakeLine(v0, v1, new Color(0.6f, 0.6f, 0.65f), mat));

            bool directed = ed.TryGetValue("directed", out Variant dv) && (bool)dv;
            if (directed) DrawArrowTip(v0, v1, mat);
        }
    }

    private void DrawEdgeCylinder(Vector3 v0, Vector3 v1, Material mat, float radius)
    {
        var dir  = v1 - v0;
        float dist = dir.Length();
        if (dist < 0.001f) return;
        var cyl = new CylinderMesh { Height = dist, TopRadius = radius, BottomRadius = radius };
        var mi  = new MeshInstance3D
        {
            Mesh             = cyl,
            Position         = (v0 + v1) * 0.5f,
            MaterialOverride = mat,
            CastShadow       = GeometryInstance3D.ShadowCastingSetting.Off,
        };
        AlignYToDirection(mi, dir.Normalized());
        _edgeContainer!.AddChild(mi);
    }

    private void DrawEdgeScene(Vector3 v0, Vector3 v1, Material mat)
    {
        var inst = _edgeMeshScene!.Instantiate<Node3D>();
        if (inst == null) return;
        var dir = v1 - v0; float dist = dir.Length();
        inst.Position = (v0 + v1) * 0.5f;
        if (dist > 0.001f) { AlignYToDirection(inst, dir.Normalized()); inst.Scale = new Vector3(1f, dist, 1f); }
        ApplyMaterialToScene(inst, mat);
        _edgeContainer!.AddChild(inst);
    }

    private void DrawArrowTip(Vector3 from, Vector3 to, Material mat)
    {
        var dir = (to - from).Normalized();
        if (dir.LengthSquared() < 0.001f) return;
        var tipPos = to - dir * (_nodeRadius + _edgeWidth * 3f);
        var mi = new MeshInstance3D
        {
            Mesh             = DefaultArrowHead,
            Scale            = new Vector3(_edgeWidth * 2.5f, _edgeWidth * 5f, _edgeWidth * 2.5f),
            MaterialOverride = mat,
            Position         = tipPos,
            CastShadow       = GeometryInstance3D.ShadowCastingSetting.Off,
        };
        AlignYToDirection(mi, dir);
        _edgeContainer!.AddChild(mi);
    }

    private static void AlignYToDirection(Node3D node, Vector3 dir)
    {
        var cross = Vector3.Up.Cross(dir);
        if (cross.LengthSquared() > 1e-6f)
            node.Basis = new Basis(cross.Normalized(), Vector3.Up.AngleTo(dir));
        else if (dir.Dot(Vector3.Up) < 0f)
            node.Basis = new Basis(Vector3.Right, MathF.PI);
    }

    // -------------------------------------------------------------------------
    // Label drawing
    // -------------------------------------------------------------------------

    private void DrawNodeLabels(GDArray nodes, Dictionary<string, Vector3> layout)
    {
        foreach (Variant n in nodes)
            if (n.Obj is GDDict nd)
            {
                string id  = nd.TryGetValue("id",    out Variant iv) ? iv.ToString() : "";
                string lbl = nd.TryGetValue("label", out Variant lv) ? lv.ToString() : id;
                var pos = layout.GetValueOrDefault(id);
                _labelContainer!.AddChild(MakeLabel(lbl, pos + new Vector3(0f, _nodeRadius + 0.12f, 0f), 44));
            }
    }

    private void DrawEdgeLabels(GDArray edges, Dictionary<string, Vector3> layout)
    {
        foreach (Variant e in edges)
            if (e.Obj is GDDict ed)
            {
                string src = ed.TryGetValue("source", out Variant sv) ? sv.ToString() : "";
                string tgt = ed.TryGetValue("target", out Variant tv) ? tv.ToString() : "";
                string lbl = ed.TryGetValue("label",  out Variant lv) ? lv.ToString() : "";
                if (string.IsNullOrEmpty(lbl)) continue;
                if (!layout.ContainsKey(src) || !layout.ContainsKey(tgt)) continue;
                var mid = (layout[src] + layout[tgt]) * 0.5f;
                _labelContainer!.AddChild(MakeLabel(lbl, mid, 36));
            }
    }

    // -------------------------------------------------------------------------
    // Type → color helpers
    // -------------------------------------------------------------------------

    private void AssignTypeIndices(GDArray nodes)
    {
        foreach (Variant n in nodes)
            if (n.Obj is GDDict nd)
            {
                string t = nd.TryGetValue("type", out Variant tv) ? tv.ToString() : "";
                if (!_typeColorIndex.ContainsKey(t))
                    _typeColorIndex[t] = _typeColorIndex.Count;
            }
    }

    private Color GetTypeColor(string ntype)
    {
        if (!_typeColorIndex.ContainsKey(ntype))
            _typeColorIndex[ntype] = _typeColorIndex.Count;
        return GetColor(_typeColorIndex[ntype]);
    }

    // -------------------------------------------------------------------------
    // Sub-container management
    // -------------------------------------------------------------------------

    private void EnsureSubContainers()
    {
        _nodeContainer  = GetOrCreateSubContainer("Nodes");
        _edgeContainer  = GetOrCreateSubContainer("Edges");
        _labelContainer = GetOrCreateSubContainer("Labels");
    }

    private Node3D GetOrCreateSubContainer(string name)
    {
        var node = _container!.GetNodeOrNull<Node3D>(name);
        if (node != null && IsInstanceValid(node)) return node;
        var n = new Node3D { Name = name };
        _container.AddChild(n);
        return n;
    }

    private void ClearAll()
    {
        foreach (var (_, inst) in _nodeInstances)
            if (IsInstanceValid(inst)) inst.Free();
        _nodeInstances.Clear();
        foreach (var ctr in new[] { _nodeContainer, _edgeContainer, _labelContainer })
            if (ctr != null && IsInstanceValid(ctr))
                foreach (var child in ctr.GetChildren()) child.Free();
    }

    // -------------------------------------------------------------------------
    // Normalize raw positions into chart bounds
    // -------------------------------------------------------------------------

    private Dictionary<string, Vector3> NormalizeToChart3D(Dictionary<string, Vector3> raw)
    {
        if (raw.Count == 0) return new Dictionary<string, Vector3>();
        float minX = float.PositiveInfinity, maxX = float.NegativeInfinity;
        float minY = float.PositiveInfinity, maxY = float.NegativeInfinity;
        float minZ = float.PositiveInfinity, maxZ = float.NegativeInfinity;
        foreach (var p in raw.Values)
        {
            if (p.X < minX) minX = p.X; if (p.X > maxX) maxX = p.X;
            if (p.Y < minY) minY = p.Y; if (p.Y > maxY) maxY = p.Y;
            if (p.Z < minZ) minZ = p.Z; if (p.Z > maxZ) maxZ = p.Z;
        }
        float margin = _nodeRadius * 2f;
        float rx = maxX != minX ? maxX - minX : 1f;
        float ry = maxY != minY ? maxY - minY : 1f;
        float rz = maxZ != minZ ? maxZ - minZ : 1f;
        float tw = MathF.Max(ChartSize.X - margin * 2f, 0.01f);
        float th = MathF.Max(ChartSize.Y - margin * 2f, 0.01f);
        float td = MathF.Max(MathF.Min(ChartSize.X, ChartSize.Y) - margin * 2f, 0.01f);
        var result = new Dictionary<string, Vector3>();
        foreach (var (id, p) in raw)
            result[id] = new Vector3(
                margin + (p.X - minX) / rx * tw,
                margin + (p.Y - minY) / ry * th,
                (p.Z - minZ) / rz * td - td * 0.5f);
        return result;
    }

    // -------------------------------------------------------------------------
    // Demo data
    // -------------------------------------------------------------------------

    private void DrawDemo()
    {
        _data = new GDDict
        {
            { "nodes", new GDArray
                {
                    new GDDict { {"id","A"}, {"label","Alpha"},   {"type","source"}, {"x",0.0}, {"y",0.0}, {"z",0.0} },
                    new GDDict { {"id","B"}, {"label","Beta"},    {"type","node"},   {"x",1.0}, {"y",0.5}, {"z",0.5} },
                    new GDDict { {"id","C"}, {"label","Gamma"},   {"type","node"},   {"x",0.5}, {"y",1.0}, {"z",0.2} },
                    new GDDict { {"id","D"}, {"label","Delta"},   {"type","node"},   {"x",0.2}, {"y",0.5}, {"z",1.0} },
                    new GDDict { {"id","E"}, {"label","Epsilon"}, {"type","sink"},   {"x",0.8}, {"y",0.2}, {"z",0.8} },
                }
            },
            { "edges", new GDArray
                {
                    new GDDict { {"source","A"}, {"target","B"}, {"directed",true} },
                    new GDDict { {"source","A"}, {"target","C"}, {"directed",true} },
                    new GDDict { {"source","B"}, {"target","E"}, {"directed",true} },
                    new GDDict { {"source","C"}, {"target","D"} },
                    new GDDict { {"source","D"}, {"target","E"}, {"directed",true} },
                }
            },
        };
        _Rebuild();
    }
}
