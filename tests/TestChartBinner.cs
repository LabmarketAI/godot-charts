using System;
using NUnit.Framework;
using GodotCharts;

namespace GodotChartsTests;

[TestFixture]
public class TestChartBinner
{
    // -------------------------------------------------------------------------
    // SuggestBinCount
    // -------------------------------------------------------------------------

    [Test] public void SuggestBinCount_Empty_ReturnsOne()
        => Assert.That(ChartBinner.SuggestBinCount(Array.Empty<double>()), Is.EqualTo(1));

    [Test] public void SuggestBinCount_Single_ReturnsOne()
        => Assert.That(ChartBinner.SuggestBinCount(new double[]{1.0}), Is.EqualTo(1));

    [Test] public void SuggestBinCount_Two()
    {
        // log2(2) = 1 → ceil(1) + 1 = 2
        Assert.That(ChartBinner.SuggestBinCount(new double[]{1.0, 2.0}), Is.EqualTo(2));
    }

    [Test] public void SuggestBinCount_Eight()
    {
        // log2(8) = 3 → ceil(3) + 1 = 4
        var data = new double[8];
        for (int i = 0; i < 8; i++) data[i] = i;
        Assert.That(ChartBinner.SuggestBinCount(data), Is.EqualTo(4));
    }

    [Test] public void SuggestBinCount_ThirtyTwo()
    {
        // log2(32) = 5 → ceil(5) + 1 = 6
        var data = new double[32];
        for (int i = 0; i < 32; i++) data[i] = i;
        Assert.That(ChartBinner.SuggestBinCount(data), Is.EqualTo(6));
    }

    // -------------------------------------------------------------------------
    // AutoBin
    // -------------------------------------------------------------------------

    [Test] public void AutoBin_Empty_ReturnsEmpty()
    {
        var r = ChartBinner.AutoBin(Array.Empty<double>(), 5);
        Assert.That(r.Edges, Has.Length.EqualTo(0));
        Assert.That(r.Counts, Has.Length.EqualTo(0));
    }

    [Test] public void AutoBin_ZeroBins_ReturnsEmpty()
    {
        var r = ChartBinner.AutoBin(new double[]{1.0, 2.0, 3.0}, 0);
        Assert.That(r.Edges, Has.Length.EqualTo(0));
    }

    [Test] public void AutoBin_HasNPlusOneEdges()
    {
        var r = ChartBinner.AutoBin(new double[]{0, 1, 2, 3, 4}, 5);
        Assert.That(r.Edges, Has.Length.EqualTo(6));
    }

    [Test] public void AutoBin_HasNCountBuckets()
    {
        var r = ChartBinner.AutoBin(new double[]{0, 1, 2, 3, 4}, 5);
        Assert.That(r.Counts, Has.Length.EqualTo(5));
    }

    [Test] public void AutoBin_CountsSumEqualsTotal()
    {
        var data = new double[]{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
        var r = ChartBinner.AutoBin(data, 4);
        int total = 0;
        foreach (var c in r.Counts) total += c;
        Assert.That(total, Is.EqualTo(data.Length));
    }

    [Test] public void AutoBin_SingleValue_AllCounted()
    {
        var r = ChartBinner.AutoBin(new double[]{42.0}, 3);
        int total = 0;
        foreach (var c in r.Counts) total += c;
        Assert.That(total, Is.EqualTo(1));
    }

    [Test] public void AutoBin_IdenticalValues_AllCounted()
    {
        // Identical values trigger the zero-width guard (maxVal += 1.0).
        var r = ChartBinner.AutoBin(new double[]{3, 3, 3, 3}, 3);
        int total = 0;
        foreach (var c in r.Counts) total += c;
        Assert.That(total, Is.EqualTo(4));
    }

    [Test] public void AutoBin_MaxValueIncluded()
    {
        // Maximum value must land in the last bin (clamped), not overflow.
        var r = ChartBinner.AutoBin(new double[]{0.0, 10.0}, 5);
        int total = 0;
        foreach (var c in r.Counts) total += c;
        Assert.That(total, Is.EqualTo(2));
    }

    // -------------------------------------------------------------------------
    // ManualBin
    // -------------------------------------------------------------------------

    [Test] public void ManualBin_EmptyData_ReturnsEmpty()
    {
        var r = ChartBinner.ManualBin(Array.Empty<double>(), new double[]{0, 1, 2});
        Assert.That(r.Edges, Has.Length.EqualTo(0));
    }

    [Test] public void ManualBin_TooFewEdges_ReturnsEmpty()
    {
        var r = ChartBinner.ManualBin(new double[]{1, 2}, new double[]{0});
        Assert.That(r.Edges, Has.Length.EqualTo(0));
    }

    [Test] public void ManualBin_BasicPlacement()
    {
        // Bins: [0,1), [1,2), [2,3]
        var edges = new double[]{0, 1, 2, 3};
        var data  = new double[]{0.5, 1.5, 2.5};
        var r = ChartBinner.ManualBin(data, edges);
        Assert.That(r.Counts[0], Is.EqualTo(1));
        Assert.That(r.Counts[1], Is.EqualTo(1));
        Assert.That(r.Counts[2], Is.EqualTo(1));
    }

    [Test] public void ManualBin_OutOfRangeIgnored()
    {
        // -1 and 11 are outside [0,10]; 3 → bin 0 [0,5); 5 → bin 1 [5,10]
        var edges = new double[]{0, 5, 10};
        var data  = new double[]{-1, 3, 5, 11};
        var r = ChartBinner.ManualBin(data, edges);
        Assert.That(r.Counts[0], Is.EqualTo(1)); // 3.0
        Assert.That(r.Counts[1], Is.EqualTo(1)); // 5.0
    }

    [Test] public void ManualBin_MaxValueInLastBin()
    {
        // Exact upper edge belongs to the last (closed) bin.
        var edges = new double[]{0, 5, 10};
        var r = ChartBinner.ManualBin(new double[]{10.0}, edges);
        Assert.That(r.Counts[0], Is.EqualTo(0));
        Assert.That(r.Counts[1], Is.EqualTo(1));
    }

    [Test] public void ManualBin_TotalExcludesOutOfRange()
    {
        // 7.0 > edges[^1]=6.0 → excluded; other 7 values are in range.
        var edges = new double[]{0, 2, 4, 6};
        var data  = new double[]{0, 1, 2, 3, 4, 5, 6, 7};
        var r = ChartBinner.ManualBin(data, edges);
        int total = 0;
        foreach (var c in r.Counts) total += c;
        Assert.That(total, Is.EqualTo(7));
    }
}
