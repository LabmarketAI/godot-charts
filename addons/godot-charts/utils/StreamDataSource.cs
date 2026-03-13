using System;
using System.Collections.Generic;
using Godot;
using GDArray = Godot.Collections.Array;
using GDDict = Godot.Collections.Dictionary;

namespace GodotCharts;

/// <summary>
/// A <see cref="ChartDataSource"/> that maintains a rolling window of real-time data points.
///
/// Call <see cref="AppendPoint"/> or <see cref="AppendFrame"/> from any game loop,
/// physics process, or timer callback. The source keeps a fixed-size FIFO buffer
/// per series; oldest points are dropped when <see cref="MaxWindow"/> is exceeded.
/// <see cref="ChartDataSource.DataUpdated"/> is emitted after every append.
///
/// <b>Single-series usage</b>
/// <code>
/// var stream = new StreamDataSource { MaxWindow = 60 };
/// myChart.DataSource = stream;
/// // in _Process:
/// stream.AppendPoint("FPS", Engine.GetFramesPerSecond());
/// </code>
/// </summary>
[Tool]
public partial class StreamDataSource : ChartDataSource
{
    /// <summary>Maximum number of data points kept per series.</summary>
    [Export(PropertyHint.Range, "2,1000,1")]
    public int MaxWindow { get; set; } = 50;

    private readonly Dictionary<string, List<double>> _buffers = new();
    private readonly List<string> _seriesOrder = new();

    /// <summary>
    /// Append a single data point to the named series, creating it if needed.
    /// Emits <see cref="ChartDataSource.DataUpdated"/> after updating the buffer.
    /// </summary>
    public void AppendPoint(string series, double value)
    {
        EnsureSeries(series);
        Push(_buffers[series], value);
        EmitSignal(SignalName.DataUpdated, GetData());
    }

    /// <summary>
    /// Append one data point to each series in <paramref name="frame"/> simultaneously.
    /// All series are updated before the signal fires so the chart sees a consistent snapshot.
    /// </summary>
    public void AppendFrame(Dictionary<string, double> frame)
    {
        foreach (var (name, value) in frame)
        {
            EnsureSeries(name);
            Push(_buffers[name], value);
        }
        EmitSignal(SignalName.DataUpdated, GetData());
    }

    /// <summary>Remove all buffered data and emit an empty dictionary.</summary>
    public void ClearData()
    {
        _buffers.Clear();
        _seriesOrder.Clear();
        EmitSignal(SignalName.DataUpdated, new GDDict());
    }

    /// <summary>Return the list of series names in the order they were first added.</summary>
    public IReadOnlyList<string> GetSeriesNames() => _seriesOrder;

    public override GDDict GetData()
    {
        if (_seriesOrder.Count == 0) return new GDDict();

        int maxLen = 0;
        foreach (var s in _seriesOrder)
            maxLen = Math.Max(maxLen, _buffers[s].Count);

        var labels = new GDArray();
        for (int i = 0; i < maxLen; i++) labels.Add(i.ToString());

        var datasets = new GDArray();
        foreach (var s in _seriesOrder)
        {
            var values = new GDArray();
            foreach (var v in _buffers[s]) values.Add(v);
            datasets.Add(new GDDict { { "name", s }, { "values", values } });
        }

        return new GDDict { { "labels", labels }, { "datasets", datasets } };
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private void EnsureSeries(string series)
    {
        if (!_buffers.ContainsKey(series))
        {
            _buffers[series] = new List<double>();
            _seriesOrder.Add(series);
        }
    }

    private void Push(List<double> buf, double value)
    {
        buf.Add(value);
        while (buf.Count > MaxWindow)
            buf.RemoveAt(0);
    }
}
