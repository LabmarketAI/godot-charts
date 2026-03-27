using System;
using MathNet.Numerics.Statistics;

namespace GodotCharts;

/// <summary>
/// Thin adapter over Math.NET Numerics so chart utilities can consume
/// robust statistical helpers without coupling to Math.NET APIs directly.
/// </summary>
public static class ChartStatistics
{
    /// <summary>
    /// Returns the minimum and maximum values in <paramref name="data"/>.
    /// </summary>
    public static (double Min, double Max) GetMinMax(double[] data)
    {
        if (data.Length == 0)
            return (0d, 0d);

        return (ArrayStatistics.Minimum(data), ArrayStatistics.Maximum(data));
    }

    /// <summary>
    /// Suggest bin count using the Freedman-Diaconis rule.
    /// Returns 1 for tiny/degenerate inputs.
    /// </summary>
    public static int SuggestBinCountFreedmanDiaconis(double[] data, int maxBins = 256)
    {
        if (data.Length <= 1)
            return 1;

        var sorted = (double[])data.Clone();
        Array.Sort(sorted);
        double min = sorted[0];
        double max = sorted[^1];
        if (Math.Abs(max - min) < double.Epsilon)
            return 1;

        double q1 = SortedArrayStatistics.Quantile(sorted, 0.25);
        double q3 = SortedArrayStatistics.Quantile(sorted, 0.75);
        double iqr = q3 - q1;
        if (iqr <= double.Epsilon)
            return 1;

        double binWidth = 2d * iqr / Math.Cbrt(data.Length);
        if (binWidth <= double.Epsilon)
            return 1;

        int bins = (int)Math.Ceiling((max - min) / binWidth);
        return Math.Clamp(bins, 1, maxBins);
    }
}
