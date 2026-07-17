#!/usr/bin/env python3
"""Publish a live Matplotlib/DataFrame object through the companion API."""

from __future__ import annotations

import argparse
import asyncio
import json
import os
from pathlib import Path

os.environ.setdefault("MPLCONFIGDIR", "/tmp/godot-charts-matplotlib")
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

from godot_charts_companion import Scatter3DMapping, handshake_message, matplotlib_scatter_message, serve_messages


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=0)
    parser.add_argument("--ready-file", type=Path, required=True)
    args = parser.parse_args()
    session_id = "session-companion-live"
    frame = pd.DataFrame(
        {
            "year": [2022.0, 2023.0, 2024.0],
            "sites": [5.0, 7.0, 9.0],
            "enrolled": [150.0, 205.0, 260.0],
            "phase": ["I", "II", "III"],
        },
        index=["trial-live-2022", "trial-live-2023", "trial-live-2024"],
    )
    figure = plt.figure()
    axes = figure.add_subplot(projection="3d")
    palette = {"I": "#3b82f6", "II": "#f59e0b", "III": "#10b981"}
    axes.scatter(frame["year"], frame["sites"], frame["enrolled"], c=[palette[value] for value in frame["phase"]])
    axes.set(title="Live companion scatter", xlabel="Year", ylabel="Sites", zlabel="Enrollment")
    message = matplotlib_scatter_message(
        figure,
        frame,
        Scatter3DMapping("year", "sites", "enrolled", "phase"),
        session_id=session_id,
        sequence=1,
        plot_id="plot-companion-live",
        dataset_id="dataset-companion-live",
        color_map=palette,
    )
    plt.close(figure)

    def ready(host: str, port: int) -> None:
        args.ready_file.write_text(json.dumps({"host": host, "port": port}))

    asyncio.run(serve_messages([handshake_message(session_id), message], host=args.host, port=args.port, ready=ready))


if __name__ == "__main__":
    main()
