using Godot;
using Godot.Collections;

namespace GodotCharts;

/// <summary>
/// A <see cref="ChartDataSource"/> that wraps a plain <see cref="Dictionary"/>.
///
/// This is the simplest data source. Assign <see cref="SourceData"/> from code;
/// the connected chart redraws automatically via <see cref="ChartDataSource.DataUpdated"/>.
/// </summary>
[Tool]
public partial class DictDataSource : ChartDataSource
{
    private Dictionary _sourceData = new();

    /// <summary>
    /// The chart data dictionary. Assigning triggers <see cref="ChartDataSource.DataUpdated"/>
    /// and redraws any connected chart.
    /// </summary>
    [Export]
    public Dictionary SourceData
    {
        get => _sourceData;
        set
        {
            _sourceData = value;
            EmitSignal(SignalName.DataUpdated, value);
        }
    }

    public override Dictionary GetData() => _sourceData;
}
