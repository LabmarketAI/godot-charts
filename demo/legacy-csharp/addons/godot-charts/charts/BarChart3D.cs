using System;
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// A 3D grouped bar chart.
///
/// Categories are distributed evenly along the X axis. Within each category slot,
/// bars from different datasets are placed side-by-side in X (matplotlib-style grouping).
/// </summary>
[Tool]
public partial class BarChart3D : Chart3D
{
    private static readonly Mesh DefaultBarMesh =
        GD.Load<Mesh>("res://addons/godot-charts/assets/meshes/bar_box.tres");

    // -------------------------------------------------------------------------
    // Exported properties
    // -------------------------------------------------------------------------

    private Dictionary _data = new();
    [Export]
    public Dictionary Data
    {
        get => _data;
        set { _data = value; QueueRebuild(); }
    }

    private float _barWidth = 0.4f;
    [Export(PropertyHint.Range, "0.05,2.0,0.01")]
    public float BarWidth
    {
        get => _barWidth;
        set { _barWidth = value; QueueRebuild(); }
    }

    private float _seriesGap = 0.1f;
    [Export(PropertyHint.Range, "0.0,1.0,0.05")]
    public float SeriesGap
    {
        get => _seriesGap;
        set { _seriesGap = value; QueueRebuild(); }
    }

    private float _barDepth = 0.4f;
    [Export(PropertyHint.Range, "0.05,2.0,0.01")]
    public float BarDepth
    {
        get => _barDepth;
        set { _barDepth = value; QueueRebuild(); }
    }

    private Material[] _barMaterials = System.Array.Empty<Material>();
    [Export]
    public Material[] BarMaterials
    {
        get => _barMaterials;
        set { _barMaterials = value; QueueRebuild(); }
    }

    private Texture2D[] _barTextures = System.Array.Empty<Texture2D>();
    [Export]
    public Texture2D[] BarTextures
    {
        get => _barTextures;
        set { _barTextures = value; QueueRebuild(); }
    }

    private PackedScene? _barMeshScene;
    [Export]
    public PackedScene? BarMeshScene
    {
        get => _barMeshScene;
        set { _barMeshScene = value; QueueRebuild(); }
    }

    private float _barCornerRadius;
    [Export(PropertyHint.Range, "0.0,0.5,0.005")]
    public float BarCornerRadius
    {
        get => _barCornerRadius;
        set { _barCornerRadius = value; QueueRebuild(); }
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
        if (datasets.Count == 0) { DrawDemo(); return; }

        RenderBarData(d);
        EmitSignal(SignalName.DataChanged);
    }

    /// <summary>
    /// Renders bar geometry from <paramref name="d"/>.
    /// Called by <see cref="_Rebuild"/> and by <see cref="HistogramChart3D"/> with computed bin data.
    /// </summary>
    protected void RenderBarData(Dictionary d)
    {
        var datasets = d.TryGetValue("datasets", out Variant dsv) && dsv.Obj is GDArray dsa ? dsa : new GDArray();
        var labels   = d.TryGetValue("labels",   out Variant lv)  && lv.Obj  is GDArray la  ? la  : new GDArray();

        int nDatasets = datasets.Count;
        int nCategories = 0;
        foreach (Variant ds in datasets)
            if (ds.Obj is Dictionary dsDict)
            {
                var vals = dsDict.TryGetValue("values", out Variant vv) && vv.Obj is GDArray va ? va : new GDArray();
                nCategories = Math.Max(nCategories, vals.Count);
            }

        if (nCategories == 0) return;

        float maxVal = 0f;
        foreach (Variant ds in datasets)
            if (ds.Obj is Dictionary dsDict)
                foreach (Variant v in dsDict.TryGetValue("values", out Variant vv) && vv.Obj is GDArray va ? va : new GDArray())
                    maxVal = MathF.Max(maxVal, (float)(double)v);

        if (maxVal == 0f) return;

        float xStep  = ChartSize.X / nCategories;
        float yScale = ChartSize.Y / maxVal;
        float barPitch = xStep * 0.85f / nDatasets;
        float bw = MathF.Max(MathF.Min(_barWidth, barPitch * (1f - _seriesGap)), 0.02f);

        for (int dsIdx = 0; dsIdx < nDatasets; dsIdx++)
        {
            if (!(datasets[dsIdx].Obj is Dictionary ds)) continue;
            var values = ds.TryGetValue("values", out Variant vv2) && vv2.Obj is GDArray va2 ? va2 : new GDArray();
            var color = GetColor(dsIdx);
            var matOverride = dsIdx < _barMaterials.Length ? _barMaterials[dsIdx] : null;
            var tex = dsIdx < _barTextures.Length ? _barTextures[dsIdx] : null;
            var mat = CreateMaterialWithTexture(color, tex, matOverride);

            for (int catIdx = 0; catIdx < nCategories; catIdx++)
            {
                float val = catIdx < values.Count ? (float)(double)values[catIdx] : 0f;
                if (val <= 0f) continue;

                float groupLeft = catIdx * xStep + xStep * 0.075f;
                float xCenter   = groupLeft + (dsIdx + 0.5f) * barPitch;
                float barH      = val * yScale;
                var barPos = new Vector3(xCenter, barH * 0.5f, _barDepth * 0.5f);

                if (_barMeshScene != null)
                {
                    var inst = _barMeshScene.Instantiate<Node3D>();
                    if (inst != null)
                    {
                        inst.Scale    = new Vector3(bw, barH, _barDepth);
                        inst.Position = barPos;
                        if (matOverride != null) ApplyMaterialToScene(inst, matOverride);
                        _container!.AddChild(inst);
                        ApplyAnimation(inst);
                    }
                }
                else
                {
                    var mi = new MeshInstance3D { MaterialOverride = mat, Position = barPos };
                    if (_barCornerRadius > 0f)
                        mi.Mesh = BuildRoundedBarMesh(bw, barH, _barDepth, _barCornerRadius);
                    else
                    {
                        mi.Mesh  = DefaultBarMesh;
                        mi.Scale = new Vector3(bw, barH, _barDepth);
                    }
                    _container!.AddChild(mi);
                }
            }
        }

        DrawGridXY(ChartSize.X, ChartSize.Y);
        DrawAxes(ChartSize.X, ChartSize.Y, 0.01f);
        DrawTicksY(ChartSize.Y, maxVal);

        if (ShowLabels)
            for (int catIdx = 0; catIdx < nCategories; catIdx++)
            {
                string lblText = catIdx < labels.Count ? labels[catIdx].ToString() : catIdx.ToString();
                _container!.AddChild(MakeLabel(lblText, new Vector3((catIdx + 0.5f) * xStep, -0.2f, 0f)));
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

    private void DrawDemo()
    {
        _data = new Dictionary
        {
            { "labels", new GDArray { "A", "B", "C", "D" } },
            { "datasets", new GDArray
                {
                    new Dictionary { { "name", "Alpha" }, { "values", new GDArray { 3.0, 5.0, 2.0, 4.0 } } },
                    new Dictionary { { "name", "Beta"  }, { "values", new GDArray { 1.5, 3.0, 4.5, 2.5 } } },
                }
            },
        };
        RenderBarData(_data);
    }
}
