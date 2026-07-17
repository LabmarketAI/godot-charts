#!/usr/bin/env python3
"""Generate the deterministic M1 Matplotlib/pandas recorded session."""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

os.environ.setdefault("MPLCONFIGDIR", "/tmp/godot-charts-matplotlib")

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "tests" / "m1" / "fixtures"
CREATED_AT = "2026-07-16T12:00:00Z"
SESSION_ID = "session-m1-recorded"
PLOT_ID = "plot-annual-trials"
DATASET_ID = "dataset-annual-trials"
ROW_IDS = ["trial-2021", "trial-2022", "trial-2023", "trial-2024", "trial-2025"]


def write_json(name: str, value: Any) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    (OUTPUT / name).write_text(
        json.dumps(value, indent=2, sort_keys=True, allow_nan=False) + "\n",
        encoding="utf-8",
    )


def nullable(values: list[Any]) -> list[Any]:
    return [None if pd.isna(value) else value for value in values]


def dataframe(revision: int) -> pd.DataFrame:
    enrolled = [120.0, 155.0, float("nan"), 210.0, 235.0]
    if revision == 2:
        enrolled[-1] = 248.0
    return pd.DataFrame(
        {
            "year": [2021.0, 2022.0, 2023.0, 2024.0, 2025.0],
            "enrolled": enrolled,
            "sites": [4.0, 5.0, 6.0, 8.0, 9.0],
            "phase": ["I", "I", "II", "II", "III"],
        },
        index=pd.Index(ROW_IDS, name="row_id"),
    )


def producer() -> dict[str, str]:
    return {
        "library": "matplotlib",
        "library_version": matplotlib.__version__,
        "adapter": "godot-charts-matplotlib",
        "adapter_version": "0.1.0",
    }


def provenance(revision: int) -> dict[str, Any]:
    return {
        "source_type": "python_object",
        "source_id": "matplotlib-figure-annual-trials",
        "dataset_id": DATASET_ID,
        "dataset_revision": revision,
    }


def plot_message(frame: pd.DataFrame, revision: int, sequence: int) -> dict[str, Any]:
    figure = plt.figure(figsize=(6.4, 4.8))
    axes = figure.add_subplot(projection="3d")
    collection = axes.scatter(
        frame["year"], frame["sites"], frame["enrolled"], c="#3b82f6"
    )
    axes.set(title="Annual clinical trial enrollment", xlabel="Year", ylabel="Sites", zlabel="Enrollment")
    figure.canvas.draw()

    # Exercise the public Matplotlib artist contract rather than serializing Python.
    renderable_rows = frame[["year", "sites", "enrolled"]].notna().all(axis=1).sum()
    assert collection.get_offsets().shape[0] == renderable_rows
    color = collection.get_facecolor()[0].tolist()
    diagnostics = []
    if frame["enrolled"].isna().any():
        diagnostics.append(
            {
                "severity": "info",
                "code": "missing-values-skipped",
                "message": "Rows with missing positional values remain in the table and are not rendered as points.",
                "path": "/payload/figure/data/0/columns/enrolled",
            }
        )

    message = {
        "schema": "godot-charts/plot-message/1.0",
        "message_id": f"message-plot-r{revision}",
        "session_id": SESSION_ID,
        "sequence": sequence,
        "operation": "replace",
        "plot_id": PLOT_ID,
        "revision": revision,
        "created_at": CREATED_AT,
        "producer": producer(),
        "provenance": provenance(revision),
        "diagnostics": diagnostics,
        "payload": {
            "figure": {
                "id": "figure-annual-trials",
                "title": axes.get_title(),
                "views": [
                    {
                        "id": "view-main",
                        "coordinate_system": "cartesian_3d",
                        "layers": [
                            {
                                "id": "layer-enrollment",
                                "mark": "point",
                                "data_id": DATASET_ID,
                                "mappings": {"x": "year", "y": "sites", "z": "enrolled", "color": "phase"},
                            }
                        ],
                        "scales": {
                            "x": {"type": "linear", "domain": [2021.0, 2025.0]},
                            "y": {"type": "linear", "domain": [4.0, 9.0]},
                            "z": {"type": "linear", "domain": [120.0, 250.0]},
                        },
                    }
                ],
                "data": [
                    {
                        "id": DATASET_ID,
                        "revision": revision,
                        "row_ids": list(frame.index),
                        "columns": {name: nullable(frame[name].tolist()) for name in frame.columns},
                    }
                ],
            }
        },
    }
    # Record resolved artist color only as generation evidence, not a renderer contract.
    assert len(color) == 4
    plt.close(figure)
    return message


def table_message(frame: pd.DataFrame) -> dict[str, Any]:
    columns = [
        {"id": name, "label": name.title(), "data_type": "string" if name == "phase" else "float64", "nullable": bool(frame[name].isna().any())}
        for name in frame.columns
    ]
    return {
        "schema": "godot-charts/table-result/1.0",
        "message_id": "message-table-r1",
        "session_id": SESSION_ID,
        "sequence": 2,
        "operation": "table.result",
        "created_at": CREATED_AT,
        "provenance": provenance(1),
        "payload": {
            "request_id": "request-table-window-1",
            "dataset_id": DATASET_ID,
            "revision": 1,
            "offset": 0,
            "limit": 5,
            "total_rows": len(frame),
            "columns": columns,
            "rows": [
                {"row_id": row_id, "values": nullable(frame.loc[row_id].tolist())}
                for row_id in frame.index
            ],
        },
    }


def main() -> None:
    first = dataframe(1)
    replacement = dataframe(2)
    write_json(
        "00-handshake.json",
        {
            "schema": "godot-charts/session-handshake/1.0",
            "message_id": "message-handshake-1",
            "session_id": SESSION_ID,
            "sequence": 0,
            "created_at": CREATED_AT,
            "operation": "hello",
            "payload": {
                "peer_id": "python-fixture-producer",
                "protocol_versions": ["1.0"],
                "capabilities": ["plot.replace", "table.result", "selection.replace", "diagnostics"],
                "limits": {"max_message_bytes": 1048576, "max_rows": 10000, "max_columns": 64, "max_layers": 16},
            },
        },
    )
    write_json("01-plot-r1.json", plot_message(first, 1, 1))
    write_json("02-table-r1.json", table_message(first))
    write_json(
        "03-selection-r1.json",
        {
            "schema": "godot-charts/selection/1.0",
            "message_id": "message-selection-r1",
            "session_id": SESSION_ID,
            "sequence": 3,
            "operation": "selection.replace",
            "created_at": CREATED_AT,
            "payload": {
                "selection_id": "selection-primary",
                "plot_id": PLOT_ID,
                "dataset_id": DATASET_ID,
                "dataset_revision": 1,
                "row_ids": ["trial-2022", "trial-2024"],
                "mode": "multi",
                "origin": "replay",
            },
        },
    )
    write_json("04-plot-r2.json", plot_message(replacement, 2, 4))
    write_json(
        "replay-manifest.json",
        {
            "schema": "godot-charts/replay-manifest/1.0",
            "messages": [
                "00-handshake.json",
                "01-plot-r1.json",
                "02-table-r1.json",
                "03-selection-r1.json",
                "01-plot-r1.json",
                "04-plot-r2.json"
            ],
            "expected": {
                "applied_messages": 5,
                "duplicate_messages": 1,
                "active_plot_revision": 2,
                "preserved_row_ids": ["trial-2022", "trial-2024"]
            }
        },
    )


if __name__ == "__main__":
    main()
