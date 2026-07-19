using System;
using System.Collections.Generic;
using Godot;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// A 3D surface (height-map) chart.
///
/// Renders a smooth mesh whose Y coordinate represents a scalar value over an X-Z grid.
/// Data can be supplied as a 2D jagged array via <see cref="GridData"/>, or as a
/// <see cref="SurfaceFunction"/> delegate that maps (x, z) → float.
/// </summary>
[Tool]
public partial class SurfaceChart3D : Chart3D
{
    // -------------------------------------------------------------------------
    // Exported properties
    // -------------------------------------------------------------------------

    private GDArray _gridData = new();
    [Export]
    public GDArray GridData
    {
        get => _gridData;
        set { _gridData = value; QueueRebuild(); }
    }

    /// <summary>
    /// Optional function <c>float Surface(float x, float z)</c>.
    /// When set, <see cref="GridData"/> is ignored.
    /// Assign from code — not exported (Callable export limitations in C#).
    /// </summary>
    public Func<float, float, float>? SurfaceFunction { get; set; }

    private int _gridCols = 20;
    [Export(PropertyHint.Range, "2,128,1")]
    public int GridCols
    {
        get => _gridCols;
        set { _gridCols = value; QueueRebuild(); }
    }

    private int _gridRows = 20;
    [Export(PropertyHint.Range, "2,128,1")]
    public int GridRows
    {
        get => _gridRows;
        set { _gridRows = value; QueueRebuild(); }
    }

    private Vector2 _xRange = new(0f, 1f);
    [Export]
    public Vector2 XRange
    {
        get => _xRange;
        set { _xRange = value; QueueRebuild(); }
    }

    private Vector2 _zRange = new(0f, 1f);
    [Export]
    public Vector2 ZRange
    {
        get => _zRange;
        set { _zRange = value; QueueRebuild(); }
    }

    private bool _useHeightGradient = true;
    [Export]
    public bool UseHeightGradient
    {
        get => _useHeightGradient;
        set { _useHeightGradient = value; QueueRebuild(); }
    }

    private Color _gradientLow = new(0.1f, 0.3f, 0.9f);
    [Export]
    public Color GradientLow
    {
        get => _gradientLow;
        set { _gradientLow = value; QueueRebuild(); }
    }

    private Color _gradientHigh = new(0.9f, 0.2f, 0.1f);
    [Export]
    public Color GradientHigh
    {
        get => _gradientHigh;
        set { _gradientHigh = value; QueueRebuild(); }
    }

    private Material? _surfaceMaterial;
    [Export]
    public Material? SurfaceMaterial
    {
        get => _surfaceMaterial;
        set { _surfaceMaterial = value; QueueRebuild(); }
    }

    private Texture2D? _surfaceTexture;
    [Export]
    public Texture2D? SurfaceTexture
    {
        get => _surfaceTexture;
        set { _surfaceTexture = value; QueueRebuild(); }
    }

    // -------------------------------------------------------------------------
    // Override
    // -------------------------------------------------------------------------

    protected override void _Rebuild()
    {
        Clear();
        if (_container == null || !IsInstanceValid(_container)) return;

        var heights = ResolveHeights();
        if (heights == null) { DrawDemo(); return; }

        int rows = heights.Count;
        int cols = rows > 0 ? heights[0].Count : 0;
        if (rows < 2 || cols < 2) return;

        var verts   = new List<Vector3>();
        var norms   = new List<Vector3>();
        var colArr  = new List<Color>();
        var indices = new List<int>();

        float minH = float.PositiveInfinity, maxH = float.NegativeInfinity;
        foreach (var row in heights)
            foreach (float h in row)
            {
                if (h < minH) minH = h;
                if (h > maxH) maxH = h;
            }
        if (maxH == minH) maxH = minH + 1f;

        for (int zi = 0; zi < rows; zi++)
            for (int xi = 0; xi < cols; xi++)
            {
                float x    = (float)xi / (cols - 1) * ChartSize.X;
                float z    = (float)zi / (rows - 1) * ChartSize.X;
                float h    = heights[zi][xi];
                float hNorm = (h - minH) / (maxH - minH) * ChartSize.Y;
                verts.Add(new Vector3(x, hNorm, z));
                float t = (h - minH) / (maxH - minH);
                colArr.Add(_useHeightGradient ? _gradientLow.Lerp(_gradientHigh, t) : GetColor(0));
                norms.Add(Vector3.Up);
            }

        // Smooth normals
        for (int zi = 0; zi < rows; zi++)
            for (int xi = 0; xi < cols; xi++)
            {
                int idx = zi * cols + xi;
                var n = Vector3.Zero;
                var center = verts[idx];
                if (xi + 1 < cols && zi + 1 < rows)
                    n += (verts[idx + 1] - center).Cross(verts[idx + cols] - center);
                if (xi - 1 >= 0 && zi + 1 < rows)
                    n += (verts[idx + cols] - center).Cross(verts[idx - 1] - center);
                if (xi - 1 >= 0 && zi - 1 >= 0)
                    n += (verts[idx - 1] - center).Cross(verts[idx - cols] - center);
                if (xi + 1 < cols && zi - 1 >= 0)
                    n += (verts[idx - cols] - center).Cross(verts[idx + 1] - center);
                norms[idx] = n.LengthSquared() > 0f ? n.Normalized() : Vector3.Up;
            }

        for (int zi = 0; zi < rows - 1; zi++)
            for (int xi = 0; xi < cols - 1; xi++)
            {
                int tl = zi * cols + xi;
                int tr = tl + 1;
                int bl = tl + cols;
                int br = bl + 1;
                indices.Add(tl); indices.Add(bl); indices.Add(tr);
                indices.Add(tr); indices.Add(bl); indices.Add(br);
            }

        var arrays = new GDArray();
        arrays.Resize((int)Mesh.ArrayType.Max);
        arrays[(int)Mesh.ArrayType.Vertex] = verts.ToArray();
        arrays[(int)Mesh.ArrayType.Normal] = norms.ToArray();
        arrays[(int)Mesh.ArrayType.Color]  = colArr.ToArray();
        arrays[(int)Mesh.ArrayType.Index]  = indices.ToArray();

        var amesh = new ArrayMesh();
        amesh.AddSurfaceFromArrays(Mesh.PrimitiveType.Triangles, arrays);

        Material mat;
        if (_surfaceMaterial != null)
        {
            if (_surfaceTexture != null && _surfaceMaterial is StandardMaterial3D sm)
                sm.AlbedoTexture = _surfaceTexture;
            mat = _surfaceMaterial;
        }
        else
        {
            var stdMat = new StandardMaterial3D { VertexColorUseAsAlbedo = true };
            if (_surfaceTexture != null) stdMat.AlbedoTexture = _surfaceTexture;
            mat = stdMat;
        }
        amesh.SurfaceSetMaterial(0, mat);

        _container!.AddChild(new MeshInstance3D { Mesh = amesh });
        DrawAxes(ChartSize.X * 1.05f, ChartSize.Y * 1.1f, ChartSize.X * 1.05f);
        EmitSignal(SignalName.DataChanged);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private List<List<float>>? ResolveHeights()
    {
        if (SurfaceFunction != null)
        {
            var heights = new List<List<float>>(_gridRows);
            for (int zi = 0; zi < _gridRows; zi++)
            {
                float zv = _zRange.X + (_zRange.Y - _zRange.X) * zi / (_gridRows - 1);
                var row = new List<float>(_gridCols);
                for (int xi = 0; xi < _gridCols; xi++)
                {
                    float xv = _xRange.X + (_xRange.Y - _xRange.X) * xi / (_gridCols - 1);
                    row.Add(SurfaceFunction(xv, zv));
                }
                heights.Add(row);
            }
            return heights;
        }

        if (_gridData.Count == 0) return null;
        var result = new List<List<float>>(_gridData.Count);
        foreach (Variant rowVar in _gridData)
        {
            if (rowVar.Obj is not GDArray rowArr) return null;
            var row = new List<float>(rowArr.Count);
            foreach (Variant v in rowArr) row.Add((float)(double)v);
            result.Add(row);
        }
        return result;
    }

    private void DrawDemo()
    {
        SurfaceFunction = (x, z) => MathF.Sin(x * MathF.Tau) * MathF.Cos(z * MathF.Tau) * 0.5f + 0.5f;
        _gridCols = 24;
        _gridRows = 24;
        _xRange = new Vector2(0f, 1f);
        _zRange = new Vector2(0f, 1f);
        _Rebuild();
    }
}
