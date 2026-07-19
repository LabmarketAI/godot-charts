using Godot;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// Abstract base class for charts that render data as point instances.
///
/// Provides shared point geometry properties and the <see cref="CreatePointInstance"/>
/// helper that encapsulates the full scene → mesh → default-sphere resolution.
///
/// Concrete sub-classes: <see cref="ScatterChart3D"/>, <see cref="LineChart3D"/>.
/// </summary>
[Tool]
public partial class PointChart3D : Chart3D
{
    private static readonly Mesh DefaultPointMesh =
        GD.Load<Mesh>("res://addons/godot-charts/assets/meshes/point_sphere.tres");

    // -------------------------------------------------------------------------
    // Exported properties
    // -------------------------------------------------------------------------

    private float _pointRadius = 0.08f;
    [Export(PropertyHint.Range, "0.01,1.0,0.005")]
    public float PointRadius
    {
        get => _pointRadius;
        set { _pointRadius = value; QueueRebuild(); }
    }

    private Material[] _pointMaterials = System.Array.Empty<Material>();
    [Export]
    public Material[] PointMaterials
    {
        get => _pointMaterials;
        set { _pointMaterials = value; QueueRebuild(); }
    }

    private Texture2D[] _pointTextures = System.Array.Empty<Texture2D>();
    [Export]
    public Texture2D[] PointTextures
    {
        get => _pointTextures;
        set { _pointTextures = value; QueueRebuild(); }
    }

    private Mesh? _pointMesh;
    [Export]
    public Mesh? PointMesh
    {
        get => _pointMesh;
        set { _pointMesh = value; QueueRebuild(); }
    }

    private PackedScene? _pointMeshScene;
    [Export]
    public PackedScene? PointMeshScene
    {
        get => _pointMeshScene;
        set { _pointMeshScene = value; QueueRebuild(); }
    }

    // -------------------------------------------------------------------------
    // Protected virtual methods — sub-classes override for per-dataset resolution
    // -------------------------------------------------------------------------

    protected virtual PackedScene? GetPointScene(int dsIdx) => _pointMeshScene;
    protected virtual Mesh? GetPointMesh(int dsIdx) => _pointMesh;

    // -------------------------------------------------------------------------
    // Protected helper
    // -------------------------------------------------------------------------

    /// <summary>
    /// Creates and returns a positioned point node for dataset <paramref name="dsIdx"/> at
    /// <paramref name="pos"/>. The returned node is NOT added to _container — the caller must.
    /// </summary>
    protected Node3D? CreatePointInstance(int dsIdx, Vector3 pos)
    {
        var color = GetColor(dsIdx);
        var matOverride = dsIdx < _pointMaterials.Length ? _pointMaterials[dsIdx] : null;
        var tex = dsIdx < _pointTextures.Length ? _pointTextures[dsIdx] : null;

        var dsScene = GetPointScene(dsIdx);
        if (dsScene != null)
        {
            var inst = dsScene.Instantiate<Node3D>();
            if (inst != null)
            {
                inst.Position = pos;
                if (matOverride != null) ApplyMaterialToScene(inst, matOverride);
                ApplyAnimation(inst);
            }
            return inst;
        }

        var dsMesh = GetPointMesh(dsIdx);
        var mat = CreateMaterialWithTexture(color, tex, matOverride);
        var mi = new MeshInstance3D { MaterialOverride = mat, Position = pos };
        if (dsMesh != null)
            mi.Mesh = dsMesh;
        else
        {
            mi.Mesh = DefaultPointMesh;
            mi.Scale = Vector3.One * _pointRadius;
        }
        return mi;
    }
}
