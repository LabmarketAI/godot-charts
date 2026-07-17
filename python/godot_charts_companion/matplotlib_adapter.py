"""Bounded Matplotlib adapters using public artist APIs and explicit source data."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import math
import re
from typing import Any, Mapping

import matplotlib
from matplotlib.figure import Figure
import pandas as pd

from . import __version__

IDENTIFIER = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$")
MAX_ROWS = 10_000
MAX_COLUMNS = 64


@dataclass(frozen=True)
class Scatter3DMapping:
    x: str
    y: str
    z: str
    color: str | None = None


def matplotlib_scatter_message(
    figure: Figure,
    frame: pd.DataFrame,
    mapping: Scatter3DMapping,
    *,
    session_id: str,
    sequence: int,
    plot_id: str,
    dataset_id: str,
    revision: int = 1,
    figure_id: str | None = None,
    view_id: str = "view-main",
    layer_id: str = "layer-scatter",
    source_id: str | None = None,
    color_map: Mapping[Any, str] | None = None,
    created_at: str | None = None,
) -> dict[str, Any]:
    """Normalize one 3D scatter figure and its explicitly identified DataFrame.

    The function never evaluates callbacks or serializes Python objects. The DataFrame
    is copied into bounded JSON scalar columns; its index supplies stable row IDs.
    """
    for identifier in (session_id, plot_id, dataset_id, view_id, layer_id):
        _require_identifier(identifier)
    figure_id = figure_id or f"figure-{plot_id}"
    source_id = source_id or f"matplotlib-{plot_id}"
    for identifier in (figure_id, source_id):
        _require_identifier(identifier)
    if sequence < 0 or revision < 0:
        raise ValueError("sequence and revision must be non-negative")
    if len(frame) > MAX_ROWS or len(frame.columns) > MAX_COLUMNS:
        raise ValueError("DataFrame exceeds companion row or column limits")
    if not figure.axes:
        raise ValueError("figure must contain an axes")
    axes = figure.axes[0]
    if not hasattr(axes, "get_zlabel"):
        raise ValueError("only Matplotlib 3D axes are supported in this slice")
    required = [mapping.x, mapping.y, mapping.z]
    if mapping.color:
        required.append(mapping.color)
    missing = [column for column in required if column not in frame.columns]
    if missing:
        raise ValueError(f"mapping references missing columns: {missing}")
    row_ids = [str(value) for value in frame.index]
    if len(set(row_ids)) != len(row_ids):
        raise ValueError("DataFrame index must provide unique stable row identities")
    for row_id in row_ids:
        _require_identifier(row_id)

    columns = {str(name): [_json_scalar(value) for value in frame[name].tolist()] for name in frame.columns}
    scales: dict[str, Any] = {
        "x": _linear_scale(frame[mapping.x]),
        "y": _linear_scale(frame[mapping.y]),
        "z": _linear_scale(frame[mapping.z]),
    }
    mappings = {"x": mapping.x, "y": mapping.y, "z": mapping.z}
    guides = [
        {"id": "guide-x", "type": "axis", "channel": "x", "title": axes.get_xlabel()},
        {"id": "guide-y", "type": "axis", "channel": "y", "title": axes.get_ylabel()},
        {"id": "guide-z", "type": "axis", "channel": "z", "title": axes.get_zlabel()},
    ]
    if mapping.color:
        if not color_map:
            raise ValueError("categorical color mapping requires an explicit color_map")
        domain = [_json_scalar(value) for value in pd.unique(frame[mapping.color].dropna())]
        absent = [value for value in domain if value not in color_map]
        if absent:
            raise ValueError(f"color_map does not cover categories: {absent}")
        mappings["color"] = mapping.color
        scales["color"] = {"type": "categorical", "domain": domain, "range": [color_map[value] for value in domain]}
        guides.append({"id": "guide-color", "type": "legend", "channel": "color", "title": mapping.color})

    diagnostics = []
    if frame[required[:3]].isna().any(axis=None):
        diagnostics.append({
            "severity": "info",
            "code": "missing-values-skipped",
            "message": "Rows with missing positional values remain in the table and are not rendered as points.",
            "path": f"/payload/figure/data/0/columns/{mapping.z}",
        })
    return {
        "schema": "godot-charts/plot-message/1.0",
        "message_id": f"message-{plot_id}-r{revision}",
        "session_id": session_id,
        "sequence": sequence,
        "operation": "replace",
        "plot_id": plot_id,
        "revision": revision,
        "created_at": created_at or datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "producer": {
            "library": "matplotlib",
            "library_version": matplotlib.__version__,
            "adapter": "godot-charts-matplotlib",
            "adapter_version": __version__,
        },
        "provenance": {
            "source_type": "python_object",
            "source_id": source_id,
            "dataset_id": dataset_id,
            "dataset_revision": revision,
        },
        "diagnostics": diagnostics,
        "payload": {"figure": {
            "id": figure_id,
            "title": axes.get_title(),
            "views": [{
                "id": view_id,
                "coordinate_system": "cartesian_3d",
                "layers": [{"id": layer_id, "mark": "point", "data_id": dataset_id, "mappings": mappings}],
                "scales": scales,
                "guides": guides,
            }],
            "data": [{"id": dataset_id, "revision": revision, "row_ids": row_ids, "columns": columns}],
        }},
    }


def _require_identifier(value: str) -> None:
    if not IDENTIFIER.fullmatch(value):
        raise ValueError(f"invalid protocol identifier: {value!r}")


def _json_scalar(value: Any) -> Any:
    if pd.isna(value):
        return None
    if hasattr(value, "item"):
        value = value.item()
    if isinstance(value, (str, int, float, bool)):
        if isinstance(value, float) and not math.isfinite(value):
            return None
        return value
    raise TypeError(f"unsupported DataFrame scalar type: {type(value).__name__}")


def _linear_scale(series: pd.Series) -> dict[str, Any]:
    finite = pd.to_numeric(series, errors="coerce").dropna()
    finite = finite[finite.map(math.isfinite)]
    if finite.empty:
        raise ValueError(f"positional column {series.name!r} has no finite values")
    low, high = float(finite.min()), float(finite.max())
    if low == high:
        low, high = low - 0.5, high + 0.5
    return {"type": "linear", "domain": [low, high]}
