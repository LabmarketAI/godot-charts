using System.Collections.Generic;
using System.IO;
using Godot;
using Godot.Collections;

namespace GodotCharts;

/// <summary>
/// A <see cref="ChartDataSource"/> that loads and parses a CSV file from disk.
///
/// <b>Expected CSV format</b>
///
/// The first row is treated as a header. If the first column's data rows are
/// non-numeric, that column is used as category labels; otherwise row indices
/// are used and all columns become datasets.
///
/// Label-column format:
/// <code>
/// ,Revenue,Expenses
/// Jan,1.2,0.9
/// Feb,2.8,1.4
/// </code>
///
/// Data-only format:
/// <code>
/// Revenue,Expenses
/// 1.2,0.9
/// 2.8,1.4
/// </code>
/// </summary>
[Tool]
public partial class CsvDataSource : ChartDataSource
{
    private string _filePath = "";

    /// <summary>Path to the CSV file. Setting this property loads the file immediately.</summary>
    [Export(PropertyHint.File, "*.csv")]
    public string FilePath
    {
        get => _filePath;
        set
        {
            _filePath = value;
            if (!string.IsNullOrEmpty(value))
                LoadFile(value);
        }
    }

    private Dictionary _data = new();

    public override Dictionary GetData() => _data;

    /// <summary>
    /// Load and parse the CSV at <paramref name="path"/>.
    /// Returns <c>true</c> on success; pushes an error and returns <c>false</c> on failure.
    /// On success, <see cref="ChartDataSource.DataUpdated"/> is emitted.
    /// Accepts <c>res://</c> paths and absolute paths.
    /// </summary>
    public bool LoadFile(string path)
    {
        string absPath = path.StartsWith("res://") || path.StartsWith("user://")
            ? ProjectSettings.GlobalizePath(path)
            : path;

        if (!File.Exists(absPath))
        {
            GD.PushError($"CsvDataSource: cannot open '{path}'");
            return false;
        }

        var lines = new List<string>();
        using (var reader = new StreamReader(absPath))
        {
            string? line;
            while ((line = reader.ReadLine()) != null)
            {
                if (!string.IsNullOrWhiteSpace(line))
                    lines.Add(line);
            }
        }

        if (lines.Count < 2)
        {
            GD.PushWarning($"CsvDataSource: '{path}' has fewer than 2 non-empty rows; nothing loaded");
            return false;
        }

        var header = SplitLine(lines[0]);
        if (header.Count == 0)
        {
            GD.PushWarning($"CsvDataSource: empty header row in '{path}'");
            return false;
        }

        var firstData = SplitLine(lines[1]);
        bool hasLabelCol = firstData.Count > 0 && !double.TryParse(firstData[0].Trim(), out _);

        var datasetNames = new List<string>();
        int startCol = hasLabelCol ? 1 : 0;
        for (int i = startCol; i < header.Count; i++)
            datasetNames.Add(header[i].Trim());

        if (datasetNames.Count == 0)
        {
            GD.PushWarning($"CsvDataSource: no dataset columns found in '{path}'");
            return false;
        }

        var labels = new List<string>();
        var valueCols = new List<List<double>>(datasetNames.Count);
        for (int i = 0; i < datasetNames.Count; i++)
            valueCols.Add(new List<double>());

        for (int rowIdx = 1; rowIdx < lines.Count; rowIdx++)
        {
            var cells = SplitLine(lines[rowIdx]);
            labels.Add(hasLabelCol && cells.Count > 0 ? cells[0].Trim() : (rowIdx - 1).ToString());
            for (int dsIdx = 0; dsIdx < datasetNames.Count; dsIdx++)
            {
                int col = dsIdx + startCol;
                string raw = col < cells.Count ? cells[col].Trim() : "0";
                valueCols[dsIdx].Add(double.TryParse(raw, out double v) ? v : 0.0);
            }
        }

        var labelsArr = new Array();
        foreach (var l in labels) labelsArr.Add(l);

        var datasets = new Array();
        for (int dsIdx = 0; dsIdx < datasetNames.Count; dsIdx++)
        {
            var values = new Array();
            foreach (var v in valueCols[dsIdx]) values.Add(v);
            datasets.Add(new Dictionary { { "name", datasetNames[dsIdx] }, { "values", values } });
        }

        _data = new Dictionary { { "labels", labelsArr }, { "datasets", datasets } };
        EmitSignal(SignalName.DataUpdated, _data);
        return true;
    }

    /// <summary>Reload the currently assigned <see cref="FilePath"/>.</summary>
    public bool Reload() => !string.IsNullOrEmpty(_filePath) && LoadFile(_filePath);

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private static List<string> SplitLine(string line)
    {
        var result = new List<string>();
        var current = new System.Text.StringBuilder();
        bool inQuotes = false;
        foreach (char ch in line)
        {
            if (ch == '"') inQuotes = !inQuotes;
            else if (ch == ',' && !inQuotes) { result.Add(current.ToString()); current.Clear(); }
            else current.Append(ch);
        }
        result.Add(current.ToString());
        return result;
    }
}
