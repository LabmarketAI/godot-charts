using System.IO;
using System.Linq;
using NUnit.Framework;
using GodotCharts;

namespace GodotChartsTests;

[TestFixture]
public class TestCircuitLoader
{
    private const string SimpleCircuit = """
    {
      "qubits": 3,
      "layers": [
        {"t": 0, "ops": [{"id":"n0","gate":"h","q":[0],"c":[],"params":[]}]},
        {"t": 1, "ops": [{"id":"n1","gate":"cx","q":[0,1],"c":[],"params":[]}]},
        {"t": 2, "ops": [{"id":"n2","gate":"cx","q":[1,2],"c":[],"params":[]}]}
      ]
    }
    """;

    [Test] public void Parse_ReturnsNonNull()
        => Assert.That(CircuitLoader.Parse(SimpleCircuit), Is.Not.Null);

    [Test] public void Parse_CorrectQubitCount()
    {
        var cg = CircuitLoader.Parse(SimpleCircuit)!;
        Assert.That(cg.NumQubits, Is.EqualTo(3));
    }

    [Test] public void Parse_AllOpsPresent()
    {
        var cg = CircuitLoader.Parse(SimpleCircuit)!;
        Assert.That(cg.AllOps, Has.Count.EqualTo(3));
    }

    [Test] public void Parse_LayerOrderIsMonotonic()
    {
        var cg = CircuitLoader.Parse(SimpleCircuit)!;
        var layers = cg.AllOps.Select(op => op.Layer).ToList();
        for (int i = 0; i < layers.Count - 1; i++)
            Assert.That(layers[i], Is.LessThanOrEqualTo(layers[i + 1]));
    }

    [Test] public void Parse_DependencyRespected()
    {
        var cg = CircuitLoader.Parse(SimpleCircuit)!;
        var byId = cg.AllOps.ToDictionary(op => op.Id);
        Assert.That(byId["n1"].Layer, Is.GreaterThan(byId["n0"].Layer));
        Assert.That(byId["n2"].Layer, Is.GreaterThan(byId["n1"].Layer));
    }

    [Test] public void Parse_GateNamesPreserved()
    {
        var cg = CircuitLoader.Parse(SimpleCircuit)!;
        var gates = cg.AllOps.Select(op => op.Gate).ToList();
        Assert.That(gates, Does.Contain("h"));
        Assert.That(gates, Does.Contain("cx"));
    }

    [Test] public void Parse_QubitsAssigned()
    {
        var cg = CircuitLoader.Parse(SimpleCircuit)!;
        var h = cg.AllOps.First(op => op.Gate == "h");
        Assert.That(h.Qubits, Is.EqualTo(new[] { 0 }));
    }

    [Test] public void Parse_LayerCountMatchesDistinctTimes()
    {
        var cg = CircuitLoader.Parse(SimpleCircuit)!;
        int distinctLayers = cg.AllOps.Select(op => op.Layer).Distinct().Count();
        Assert.That(cg.Layers, Has.Count.EqualTo(distinctLayers));
    }

    [Test] public void Parse_InvalidJson_ReturnsNull()
        => Assert.That(CircuitLoader.Parse("{{{bad json"), Is.Null);

    [Test] public void Parse_EmptyLayers_ReturnsEmptyCircuit()
    {
        var cg = CircuitLoader.Parse("""{"qubits":2,"layers":[]}""")!;
        Assert.That(cg, Is.Not.Null);
        Assert.That(cg.AllOps, Is.Empty);
    }

    [Test] public void Parse_ParallelGates_SameLayers()
    {
        const string json = """
        {
          "qubits": 2,
          "layers": [
            {"t": 0, "ops": [
              {"id":"a","gate":"h","q":[0],"c":[],"params":[]},
              {"id":"b","gate":"h","q":[1],"c":[],"params":[]}
            ]}
          ]
        }
        """;
        var cg = CircuitLoader.Parse(json)!;
        var a = cg.AllOps.First(op => op.Id == "a");
        var b = cg.AllOps.First(op => op.Id == "b");
        Assert.That(a.Layer, Is.EqualTo(b.Layer));
    }

    [TestCase("bell_qiskit.json", 2, 2)]
    [TestCase("ghz_qiskit.json", 3, 3)]
    [TestCase("qft3_qiskit.json", 3, 7)]
    [TestCase("transpiled_swap_heavy_qiskit.json", 3, 7)]
    public void Parse_QiskitFixtures_Load(string fixture, int expectedQubits, int expectedOps)
    {
        var text = ReadFixture(fixture);
        var cg = CircuitLoader.Parse(text)!;

        Assert.That(cg, Is.Not.Null);
        Assert.That(cg.NumQubits, Is.EqualTo(expectedQubits));
        Assert.That(cg.AllOps, Has.Count.EqualTo(expectedOps));
    }

    [TestCase("bell_qiskit.json")]
    [TestCase("ghz_qiskit.json")]
    [TestCase("qft3_qiskit.json")]
    [TestCase("transpiled_swap_heavy_qiskit.json")]
    public void Parse_QiskitFixtures_LayersMonotonic(string fixture)
    {
        var cg = CircuitLoader.Parse(ReadFixture(fixture))!;
        var layers = cg.AllOps.Select(op => op.Layer).ToList();
        for (int i = 0; i < layers.Count - 1; i++)
            Assert.That(layers[i], Is.LessThanOrEqualTo(layers[i + 1]));
    }

    [Test]
    public void Parse_FlatOpsWithEdges_UsesExplicitDependencies()
    {
        var cg = CircuitLoader.Parse(ReadFixture("dag_edges_qiskit.json"))!;
        var byId = cg.AllOps.ToDictionary(op => op.Id);

        Assert.That(byId["a"].Layer, Is.EqualTo(0));
        Assert.That(byId["b"].Layer, Is.EqualTo(1));
        Assert.That(byId["c"].Layer, Is.EqualTo(2));
    }

    [Test]
    public void Parse_UnknownEdgeIds_AreIgnoredAndStillParses()
    {
        const string json = """
        {
          "qubits": 1,
          "ops": [
            {"id":"x","gate":"h","q":[0]}
          ],
          "edges": [
            {"from":"missing","to":"x"}
          ]
        }
        """;

        var cg = CircuitLoader.Parse(json)!;
        Assert.That(cg.AllOps, Has.Count.EqualTo(1));
        Assert.That(cg.AllOps[0].Layer, Is.EqualTo(0));
    }

    private static string ReadFixture(string name)
    {
        var path = Path.Combine(TestContext.CurrentContext.TestDirectory, "Fixtures", name);
        Assert.That(File.Exists(path), Is.True, $"Fixture not found: {path}");
        return File.ReadAllText(path);
    }
}
