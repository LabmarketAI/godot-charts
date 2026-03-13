using System;
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// A 3D multi-series line chart.
///
/// Each dataset is drawn as a polyline. Multiple series are stacked along the Z axis.
/// Supports both scalar values (2D projection) and Vector3 points (true 3D mode).
/// </summary>
[Tool]
public partial class LineChart3D : PointChart3D
{
    private Dictionary _data = new();
    [Export]
    public Dictionary Data
    {
        get => _data;
        set { _data = value; QueueRebuild(); }
    }

    private float _seriesZSpacing = 1.0f;
    [Export(PropertyHint.Range, "0.0,5.0,0.1")]
    public float SeriesZSpacing
    {
        get => _seriesZSpacing;
        set { _seriesZSpacing = value; QueueRebuild(); }
    }

    private bool _showPoints = true;
    [Export]
    public bool ShowPoints
    {
        get => _showPoints;
        set { _showPoints = value; QueueRebuild(); }
    }

    private Material[] _lineMaterials = System.Array.Empty<Material>();
    [Export]
    public Material[] LineMaterials
    {
        get => _lineMaterials;
        set { _lineMaterials = value; QueueRebuild(); }
    }

    // -------------------------------------------------------------------------
    // Override
    // -------------------------------------------------------------------------

    protected override void _Rebuild()
    {
        Clear();
        if (_container == null || !IsInstanceValid(_container)) return;

        var d = DataSource != null ? GetSourceData() : _data;
        var datasets = d.TryGetValue("datasets", out Variant dsv) && dsv.Obj is GDArray dsa ? dsa : new GDArray();
        var labels   = d.TryGetValue("labels",   out Variant lv)  && lv.Obj  is GDArray la  ? la  : new GDArray();

        if (datasets.Count == 0) { DrawDemo(); return; }

        bool hasPointsMode = datasets.Count > 0
            && datasets[0].Obj is Dictionary d0
            && d0.ContainsKey("points");

        if (hasPointsMode)
            RebuildVector3Mode(datasets, labels);
        else
            RebuildScalarMode(datasets, labels);

        EmitSignal(SignalName.DataChanged);
    }

    private void RebuildScalarMode(GDArray datasets, GDArray labels)
    {
        int nDatasets = datasets.Count;
        int nPoints = 0;
        foreach (Variant ds in datasets)
            if (ds.Obj is Dictionary dsDict)
            {
                var vals = dsDict.TryGetValue("values", out Variant vv) && vv.Obj is GDArray va ? va : new GDArray();
                nPoints = Math.Max(nPoints, vals.Count);
            }
        if (nPoints < 2) return;

        float maxVal = 0f, minVal = float.PositiveInfinity;
        foreach (Variant ds in datasets)
            if (ds.Obj is Dictionary dsDict)
                foreach (Variant v in dsDict.TryGetValue("values", out Variant vv) && vv.Obj is GDArray va ? va : new GDArray())
                {
                    float fv = (float)(double)v;
                    maxVal = MathF.Max(maxVal, fv);
                    minVal = MathF.Min(minVal, fv);
                }
        if (maxVal == minVal) maxVal = minVal + 1f;
        minVal = MathF.Min(minVal, 0f);

        float xScale = ChartSize.X / (nPoints - 1);
        float yScale = ChartSize.Y / MathF.Max(maxVal - minVal, 0.001f);

        for (int dsIdx = 0; dsIdx < nDatasets; dsIdx++)
        {
            if (!(datasets[dsIdx].Obj is Dictionary ds)) continue;
            var values = ds.TryGetValue("values", out Variant vv2) && vv2.Obj is GDArray va2 ? va2 : new GDArray();
            float z = dsIdx * _seriesZSpacing;
            DrawSeries2D(dsIdx, values, xScale, yScale, minVal, z);
        }

        float axZ = (nDatasets - 1) * _seriesZSpacing + 0.01f;
        DrawGridXY(ChartSize.X, ChartSize.Y);
        DrawAxes(ChartSize.X, ChartSize.Y, axZ);
        DrawTicksY(ChartSize.Y, maxVal, minVal);

        if (ShowLabels)
            for (int i = 0; i < nPoints; i++)
            {
                string lbl = i < labels.Count ? labels[i].ToString() : i.ToString();
                _container!.AddChild(MakeLabel(lbl, new Vector3(i * xScale, -0.2f, 0f)));
            }

        var names = new string[nDatasets];
        var cols  = new Color[nDatasets];
        for (int i = 0; i < nDatasets; i++)
        {
            names[i] = datasets[i].Obj is Dictionary di && di.TryGetValue("name", out Variant nv)
                ? nv.ToString() : $"Series {i}";
            cols[i] = GetColor(i);
        }
        DrawLegend(names, cols, ChartSize.X, ChartSize.Y);
    }

    private void DrawSeries2D(int dsIdx, GDArray values, float xScale, float yScale, float minVal, float z)
    {
        var pts = new System.Collections.Generic.List<Vector3>();
        for (int i = 0; i < values.Count; i++)
            pts.Add(new Vector3(i * xScale, ((float)(double)values[i] - minVal) * yScale, z));

        var color    = GetColor(dsIdx);
        var lineOv   = dsIdx < _lineMaterials.Length ? _lineMaterials[dsIdx] : null;
        var lineMat  = lineOv ?? CreateUnshadedMaterial(color);
        var mesh     = new ImmediateMesh();
        mesh.SurfaceBegin(Mesh.PrimitiveType.LineStrip, lineMat);
        foreach (var pt in pts) mesh.SurfaceAddVertex(pt);
        mesh.SurfaceEnd();
        _container!.AddChild(new MeshInstance3D
        {
            Mesh = mesh,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
        });

        if (_showPoints)
            foreach (var pt in pts)
            {
                var inst = CreatePointInstance(dsIdx, pt);
                if (inst != null) _container.AddChild(inst);
            }
    }

    private void RebuildVector3Mode(GDArray datasets, GDArray _labels)
    {
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
            var color  = GetColor(dsIdx);
            var lineOv = dsIdx < _lineMaterials.Length ? _lineMaterials[dsIdx] : null;
            if (pts.Count < 2) continue;

            var lineMat = lineOv ?? CreateUnshadedMaterial(color);
            var mesh = new ImmediateMesh();
            mesh.SurfaceBegin(Mesh.PrimitiveType.LineStrip, lineMat);
            foreach (Variant pt in pts)
                if (pt.Obj is Vector3 v)
                    mesh.SurfaceAddVertex(new Vector3((v.X - minX) * xs, (v.Y - minY) * ys, (v.Z - minZ) * zs));
            mesh.SurfaceEnd();
            _container!.AddChild(new MeshInstance3D
            {
                Mesh = mesh,
                CastShadow = GeometryInstance3D.ShadowCastingSetting.Off,
            });

            if (_showPoints)
                foreach (Variant pt in pts)
                    if (pt.Obj is Vector3 v)
                    {
                        var pos  = new Vector3((v.X - minX) * xs, (v.Y - minY) * ys, (v.Z - minZ) * zs);
                        var inst = CreatePointInstance(dsIdx, pos);
                        if (inst != null) _container.AddChild(inst);
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
    }

    private void DrawDemo()
    {
        _data = new Dictionary
        {
            { "labels", new GDArray { "Jan", "Feb", "Mar", "Apr", "May", "Jun" } },
            { "datasets", new GDArray
                {
                    new Dictionary { { "name", "Revenue"  }, { "values", new GDArray { 1.2, 2.8, 2.3, 3.9, 3.1, 4.5 } } },
                    new Dictionary { { "name", "Expenses" }, { "values", new GDArray { 0.9, 1.4, 2.0, 1.7, 2.4, 2.2 } } },
                }
            },
        };
        _Rebuild();
    }
}
