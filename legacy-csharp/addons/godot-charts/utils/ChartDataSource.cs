using Godot;
using Godot.Collections;

namespace GodotCharts;

/// <summary>
/// Abstract base class for all chart data sources.
///
/// Sub-classes override <see cref="GetData"/> to return the chart's data dictionary
/// and emit <see cref="DataUpdated"/> whenever the underlying data changes.
/// Charts that have a <c>DataSource</c> property assigned subscribe to
/// <see cref="DataUpdated"/> and redraw automatically.
///
/// <b>Data contract</b> — every concrete source must return a dictionary that
/// follows the standard chart layout:
/// <code>
/// {
///     "labels":   ["A", "B", "C"],
///     "datasets": [
///         { "name": "Series 1", "values": [1.0, 2.0, 3.0] },
///     ]
/// }
/// </code>
/// </summary>
[Tool]
public abstract partial class ChartDataSource : Resource
{
    /// <summary>Emitted whenever the underlying data changes.</summary>
    [Signal]
    public delegate void DataUpdatedEventHandler(Dictionary newData);

    /// <summary>Returns the current chart data dictionary.</summary>
    public virtual Dictionary GetData() => new();
}
