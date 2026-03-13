using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// A 3D histogram that automatically bins raw float data.
///
/// Accepts a flat array of floats via <see cref="RawData"/>, bins them with
/// <see cref="ChartBinner"/>, then renders using the inherited <see cref="BarChart3D"/>
/// rendering pipeline.
/// </summary>
[Tool]
public partial class HistogramChart3D : BarChart3D
{
    private double[] _rawData = System.Array.Empty<double>();
    [Export]
    public double[] RawData
    {
        get => _rawData;
        set { _rawData = value; QueueRebuild(); }
    }

    private int _nBins = 10;
    [Export(PropertyHint.Range, "0,100,1")]
    public int NBins
    {
        get => _nBins;
        set { _nBins = value; QueueRebuild(); }
    }

    private double[] _binEdges = System.Array.Empty<double>();
    [Export]
    public double[] BinEdges
    {
        get => _binEdges;
        set { _binEdges = value; QueueRebuild(); }
    }

    // -------------------------------------------------------------------------
    // Override
    // -------------------------------------------------------------------------

    protected override void _Rebuild()
    {
        Clear();
        if (_container == null || !IsInstanceValid(_container)) return;

        var source = _rawData.Length > 0 ? _rawData : DemoRawData();

        ChartBinner.BinResult result;
        if (_binEdges.Length >= 2)
            result = ChartBinner.ManualBin(source, _binEdges);
        else
        {
            int k = _nBins > 0 ? _nBins : ChartBinner.SuggestBinCount(source);
            result = ChartBinner.AutoBin(source, k);
        }

        if (result.Counts.Length == 0) return;

        var labels = new GDArray();
        var floatCounts = new GDArray();
        for (int i = 0; i < result.Counts.Length; i++)
        {
            labels.Add($"{result.Edges[i]:G4}");
            floatCounts.Add((double)result.Counts[i]);
        }

        var histData = new Dictionary
        {
            { "labels", labels },
            { "datasets", new GDArray
                {
                    new Dictionary
                    {
                        { "name", YLabel != "Y" ? YLabel : "Count" },
                        { "values", floatCounts },
                    }
                }
            },
        };

        RenderBarData(histData);
        EmitSignal(SignalName.DataChanged);
    }

    private static double[] DemoRawData() => new double[]
    {
        1.2, 1.5, 1.8, 2.0, 2.1, 2.3, 2.5, 2.5, 2.7, 2.8,
        3.0, 3.0, 3.1, 3.2, 3.3, 3.3, 3.4, 3.5, 3.5, 3.6,
        3.7, 3.8, 3.9, 4.0, 4.1, 4.2, 4.5, 4.8, 5.0, 5.5,
    };
}
