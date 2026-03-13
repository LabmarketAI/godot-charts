using System;

namespace GodotCharts;

/// <summary>
/// Static utility class for histogram binning — API mirrors matplotlib hist().
/// All methods are static; no instance is needed.
/// </summary>
public static class ChartBinner
{
    /// <summary>Result of a binning operation.</summary>
    public readonly record struct BinResult(double[] Edges, int[] Counts);

    /// <summary>
    /// Automatically bin <paramref name="data"/> into <paramref name="nBins"/> equal-width buckets.
    /// <c>Edges</c> has <c>nBins + 1</c> elements; consecutive pairs define each bin.
    /// The last bin is closed on both sides (includes the maximum value).
    /// </summary>
    public static BinResult AutoBin(double[] data, int nBins = 10)
    {
        if (data.Length == 0 || nBins <= 0)
            return new BinResult(Array.Empty<double>(), Array.Empty<int>());

        double minVal = data[0], maxVal = data[0];
        foreach (double v in data)
        {
            if (v < minVal) minVal = v;
            if (v > maxVal) maxVal = v;
        }

        // Avoid zero-width range (all values identical).
        if (Math.Abs(maxVal - minVal) < double.Epsilon)
            maxVal = minVal + 1.0;

        double binWidth = (maxVal - minVal) / nBins;

        var edges = new double[nBins + 1];
        for (int i = 0; i <= nBins; i++)
            edges[i] = minVal + i * binWidth;

        var counts = new int[nBins];
        foreach (double v in data)
        {
            int idx = (int)((v - minVal) / binWidth);
            idx = Math.Clamp(idx, 0, nBins - 1);
            counts[idx]++;
        }

        return new BinResult(edges, counts);
    }

    /// <summary>
    /// Bin <paramref name="data"/> using explicit <paramref name="edges"/>
    /// (must be sorted, ≥ 2 values). Values outside [edges[0], edges[^1]] are silently ignored.
    /// The last bin is closed on both sides.
    /// </summary>
    public static BinResult ManualBin(double[] data, double[] edges)
    {
        if (data.Length == 0 || edges.Length < 2)
            return new BinResult(Array.Empty<double>(), Array.Empty<int>());

        int nBins = edges.Length - 1;
        double lo = edges[0], hi = edges[nBins];
        var counts = new int[nBins];

        foreach (double v in data)
        {
            if (v < lo || v > hi) continue;
            bool placed = false;
            for (int i = 0; i < nBins; i++)
            {
                double rightEdge = edges[i + 1];
                if (i == nBins - 1)
                {
                    if (v <= rightEdge) { counts[i]++; placed = true; break; }
                }
                else
                {
                    if (v < rightEdge) { counts[i]++; placed = true; break; }
                }
            }
            if (!placed && v == lo)
                counts[0]++;
        }

        return new BinResult(edges, counts);
    }

    /// <summary>
    /// Suggests an appropriate bin count using Sturges' rule:
    /// k = ceil(log2(n)) + 1. Returns 1 for empty or single-element arrays.
    /// </summary>
    public static int SuggestBinCount(double[] data)
    {
        int n = data.Length;
        if (n <= 1) return 1;
        return (int)Math.Ceiling(Math.Log2(n)) + 1;
    }
}
