from __future__ import annotations

import json
import os
from pathlib import Path
import sys
import unittest
import ast

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "python"))
os.environ.setdefault("MPLCONFIGDIR", "/tmp/godot-charts-matplotlib")

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
from jsonschema import Draft202012Validator
from referencing import Registry, Resource

from godot_charts_companion import (
    AdapterRegistry,
    PlotRequest,
    Scatter3DMapping,
    deterministic_id,
    handshake_message,
    matplotlib_scatter_adapter,
    matplotlib_scatter_message,
)


class CompanionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.frame = pd.DataFrame(
            {"x": [1.0, 2.0, 3.0], "y": [2.0, 4.0, 8.0], "z": [3.0, None, 9.0], "group": ["a", "b", "a"]},
            index=["row-1", "row-2", "row-3"],
        )
        self.figure = plt.figure()
        axes = self.figure.add_subplot(projection="3d")
        axes.scatter(self.frame["x"], self.frame["y"], self.frame["z"])
        axes.set(title="Notebook scatter", xlabel="X", ylabel="Y", zlabel="Z")

    def tearDown(self) -> None:
        plt.close(self.figure)

    def test_normalizes_to_schema_valid_json(self) -> None:
        message = self._message()
        json.dumps(message, allow_nan=False)
        self.assertEqual(message["payload"]["figure"]["data"][0]["row_ids"], ["row-1", "row-2", "row-3"])
        self.assertIsNone(message["payload"]["figure"]["data"][0]["columns"]["z"][1])
        self.assertEqual(message["payload"]["figure"]["views"][0]["guides"][2]["title"], "Z")
        self.assertEqual(self._schema_errors(message), [])
        self.assertEqual(self._schema_errors(handshake_message("session-test")), [])

    def test_rejects_implicit_or_unsafe_values(self) -> None:
        with self.assertRaisesRegex(ValueError, "missing columns"):
            self._message(Scatter3DMapping("x", "y", "absent"))
        duplicate = self.frame.copy()
        duplicate.index = ["same", "same", "other"]
        with self.assertRaisesRegex(ValueError, "unique stable"):
            self._message(frame=duplicate)
        unsafe = self.frame.copy()
        unsafe["object"] = [object(), object(), object()]
        with self.assertRaisesRegex(TypeError, "unsupported DataFrame scalar"):
            self._message(frame=unsafe)

    def test_registry_reports_compatibility_and_converts(self) -> None:
        registry = AdapterRegistry()
        registry.register(matplotlib_scatter_adapter())
        options = {
            "mapping": Scatter3DMapping("x", "y", "z", "group"),
            "session_id": "session-test",
            "sequence": 1,
            "plot_id": "plot-test",
            "dataset_id": "dataset-test",
            "color_map": {"a": "#3366ff", "b": "#ff6633"},
            "created_at": "2026-07-17T03:00:00Z",
        }
        request = PlotRequest(self.figure, self.frame, options)
        report = registry.compatibility(request)[0]
        self.assertTrue(report.compatible)
        self.assertEqual(report.status, "approximated")
        self.assertIn("scatter.points", report.supported)
        self.assertIn("artist.point-style", report.approximated)
        self.assertEqual(registry.convert(request)["schema"], "godot-charts/plot-message/1.0")
        with self.assertRaisesRegex(ValueError, "already registered"):
            registry.register(matplotlib_scatter_adapter())

    def test_deterministic_ids_and_resource_limits(self) -> None:
        first = deterministic_id("plot", "kernel-1", "figure-1")
        self.assertEqual(first, deterministic_id("plot", "kernel-1", "figure-1"))
        self.assertNotEqual(first, deterministic_id("plot", "kernel-2", "figure-1"))
        oversized = pd.concat([self.frame] * 3334, ignore_index=True)
        oversized.index = [f"row-{index}" for index in range(len(oversized))]
        with self.assertRaisesRegex(ValueError, "row or column limits"):
            self._message(frame=oversized)

    def test_package_has_no_pickle_or_code_execution_calls(self) -> None:
        package = ROOT / "python" / "godot_charts_companion"
        forbidden_imports = {"pickle", "cloudpickle", "dill", "subprocess"}
        forbidden_calls = {"eval", "exec", "compile", "__import__"}
        for path in package.glob("*.py"):
            tree = ast.parse(path.read_text(), filename=str(path))
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    self.assertTrue(forbidden_imports.isdisjoint(alias.name.split(".")[0] for alias in node.names), path.name)
                elif isinstance(node, ast.ImportFrom) and node.module:
                    self.assertNotIn(node.module.split(".")[0], forbidden_imports, path.name)
                elif isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
                    self.assertNotIn(node.func.id, forbidden_calls, path.name)

    def _message(self, mapping: Scatter3DMapping | None = None, frame: pd.DataFrame | None = None) -> dict:
        return matplotlib_scatter_message(
            self.figure,
            self.frame if frame is None else frame,
            mapping or Scatter3DMapping("x", "y", "z", "group"),
            session_id="session-test",
            sequence=1,
            plot_id="plot-test",
            dataset_id="dataset-test",
            color_map={"a": "#3366ff", "b": "#ff6633"},
            created_at="2026-07-17T03:00:00Z",
        )

    def _schema_errors(self, message: dict) -> list:
        schemas = ROOT / "addons" / "godot-charts" / "schemas" / "m1"
        documents = {path.name: json.loads(path.read_text()) for path in schemas.glob("*.schema.json")}
        registry = Registry()
        for name, document in documents.items():
            registry = registry.with_resource(name, Resource.from_contents(document))
            registry = registry.with_resource(document["$id"], Resource.from_contents(document))
        name = "session-handshake.schema.json" if message["operation"] == "hello" else "plot-message.schema.json"
        return list(Draft202012Validator(documents[name], registry=registry).iter_errors(message))


if __name__ == "__main__":
    unittest.main()
