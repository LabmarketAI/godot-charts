using System;
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// A 3D scatter plot.
///
/// Each dataset is a collection of Vector3 points rendered as small spheres.
///
/// <b>Data format</b>
/// <code>
/// chart.Data = new Dictionary {
///     { "datasets", new Array {
///         new Dictionary { { "name", "Group A" }, { "points", new Array { new Vector3(0.2f, 1.3f, 0.5f), ... } } }
///     }}
/// };
/// </code>
/// </summary>
[Tool]
public partial class ScatterChart3D : PointChart3D
{
    private Dictionary _data = new();
    [Export]
    public Dictionary Data
    {
        get => _data;
        set { _data = value; QueueRebuild(); }
    }

    private Mesh[] _pointMeshes = System.Array.Empty<Mesh>();
    [Export]
    public Mesh[] PointMeshes
    {
        get => _pointMeshes;
        set { _pointMeshes = value; QueueRebuild(); }
    }

    private PackedScene[] _pointMeshScenes = System.Array.Empty<PackedScene>();
    [Export]
    public PackedScene[] PointMeshScenes
    {
        get => _pointMeshScenes;
        set { _pointMeshScenes = value; QueueRebuild(); }
    }

    protected override PackedScene? GetPointScene(int dsIdx)
        => dsIdx < _pointMeshScenes.Length ? _pointMeshScenes[dsIdx] : base.GetPointScene(dsIdx);

    protected override Mesh? GetPointMesh(int dsIdx)
        => dsIdx < _pointMeshes.Length ? _pointMeshes[dsIdx] : base.GetPointMesh(dsIdx);

    protected override void _Rebuild()
    {
        Clear();
        if (_container == null || !IsInstanceValid(_container)) return;

        var d = DataSource != null ? GetSourceData() : _data;
        var datasets = d.TryGetValue("datasets", out Variant dsv) && dsv.Obj is GDArray dsa ? dsa : new GDArray();
        if (datasets.Count == 0) { DrawDemo(); return; }

        float minX = float.PositiveInfinity, maxX = float.NegativeInfinity;
        float minY = float.PositiveInfinity, maxY = float.NegativeInfinity;
        float minZ = float.PositiveInfinity, maxZ = float.NegativeInfinity;

        foreach (Variant ds in datasets)
            if (ds.Obj is Dictionary dsDict)
                foreach (Variant pt in dsDict.TryGetValue("points", out Variant pv) && pv.Obj is GDArray pa ? pa : new GDArray())
                    if (pt.Obj is Vector3 v)
                    {
                        minX = MathF.Min(minX, v.X); maxX = MathF.Max(maxX, v.X);
                        minY = MathF.Min(minY, v.Y); maxY = MathF.Max(maxY, v.Y);
                        minZ = MathF.Min(minZ, v.Z); maxZ = MathF.Max(maxZ, v.Z);
                    }

        if (float.IsPositiveInfinity(maxX)) return;
        if (maxX == minX) maxX = minX + 1f;
        if (maxY == minY) maxY = minY + 1f;
        if (maxZ == minZ) maxZ = minZ + 1f;

        float xs = ChartSize.X / (maxX - minX);
        float ys = ChartSize.Y / (maxY - minY);
        float zs = ChartSize.X / (maxZ - minZ);

        for (int dsIdx = 0; dsIdx < datasets.Count; dsIdx++)
        {
            if (!(datasets[dsIdx].Obj is Dictionary ds)) continue;
            var pts = ds.TryGetValue("points", out Variant pv2) && pv2.Obj is GDArray pa2 ? pa2 : new GDArray();
            foreach (Variant pt in pts)
            {
                if (!(pt.Obj is Vector3 v)) continue;
                var pos = new Vector3((v.X - minX) * xs, (v.Y - minY) * ys, (v.Z - minZ) * zs);
                var inst = CreatePointInstance(dsIdx, pos);
                if (inst != null) _container!.AddChild(inst);
            }
        }

        DrawAxes(ChartSize.X, ChartSize.Y, ChartSize.X);

        var names = new string[datasets.Count];
        var cols  = new Color[datasets.Count];
        for (int i = 0; i < datasets.Count; i++)
        {
            names[i] = datasets[i].Obj is Dictionary di && di.TryGetValue("name", out Variant nv)
                ? nv.ToString() : $"Series {i}";
            cols[i] = GetColor(i);
        }
        DrawLegend(names, cols, ChartSize.X, ChartSize.Y);
        EmitSignal(SignalName.DataChanged);
    }

    private void DrawDemo()
    {
        var rng = new RandomNumberGenerator();
        rng.Seed = 42;
        var ptsA = new GDArray();
        var ptsB = new GDArray();
        for (int i = 0; i < 40; i++)
        {
            ptsA.Add(new Vector3(rng.RandfRange(0.1f, 1.5f), rng.RandfRange(0.5f, 2.0f), rng.RandfRange(0.1f, 1.5f)));
            ptsB.Add(new Vector3(rng.RandfRange(1.0f, 2.5f), rng.RandfRange(0.0f, 1.2f), rng.RandfRange(1.0f, 2.5f)));
        }
        _data = new Dictionary
        {
            { "datasets", new GDArray
                {
                    new Dictionary { { "name", "Cluster A" }, { "points", ptsA } },
                    new Dictionary { { "name", "Cluster B" }, { "points", ptsB } },
                }
            },
        };
        _Rebuild();
    }
}
