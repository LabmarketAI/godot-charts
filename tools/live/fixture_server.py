#!/usr/bin/env python3
"""Serve the recorded M1 fixture as an ordered live WebSocket session."""

from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

from websockets.asyncio.server import ServerConnection, serve


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fixture-root", type=Path, required=True)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=0)
    parser.add_argument("--ready-file", type=Path, required=True)
    parser.add_argument("--delay-ms", type=float, default=20.0)
    args = parser.parse_args()

    manifest = json.loads((args.fixture_root / "replay-manifest.json").read_text())
    messages = [
        (args.fixture_root / filename).read_text().strip()
        for filename in manifest["messages"]
    ]
    served = asyncio.Event()

    async def publish(connection: ServerConnection) -> None:
        for message in messages:
            await connection.send(message)
            if args.delay_ms:
                await asyncio.sleep(args.delay_ms / 1000.0)
        await connection.close(1000, "fixture complete")
        served.set()

    async with serve(
        publish,
        args.host,
        args.port,
        compression=None,
        max_size=1_048_576,
        max_queue=16,
        ping_interval=20,
        ping_timeout=20,
    ) as server:
        port = server.sockets[0].getsockname()[1]
        args.ready_file.write_text(json.dumps({"host": args.host, "port": port}))
        await asyncio.wait_for(served.wait(), timeout=30)


if __name__ == "__main__":
    asyncio.run(main())
