"""WebSocket publishing for already-normalized Godot Charts messages."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import json
from typing import Any, Callable, Iterable

from websockets.asyncio.server import ServerConnection, serve


def handshake_message(session_id: str, *, peer_id: str = "python-companion") -> dict[str, Any]:
    return {
        "schema": "godot-charts/session-handshake/1.0",
        "message_id": f"message-handshake-{session_id}",
        "session_id": session_id,
        "sequence": 0,
        "created_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "operation": "hello",
        "payload": {
            "peer_id": peer_id,
            "protocol_versions": ["1.0"],
            "capabilities": ["plot.replace", "table.result", "selection.replace", "diagnostics"],
            "limits": {"max_message_bytes": 1_048_576, "max_rows": 10_000, "max_columns": 64, "max_layers": 16},
        },
    }


async def serve_messages(
    messages: Iterable[dict[str, Any]],
    *,
    host: str = "127.0.0.1",
    port: int = 8765,
    delay_seconds: float = 0.02,
    ready: Callable[[str, int], None] | None = None,
) -> None:
    """Serve one bounded session to one client, then stop.

    Callers supply normalized JSON dictionaries; this API doesn't inspect a kernel,
    evaluate code, deserialize pickle, or perform authentication.
    """
    encoded = [json.dumps(message, allow_nan=False, separators=(",", ":")) for message in messages]
    if not encoded or json.loads(encoded[0]).get("schema") != "godot-charts/session-handshake/1.0":
        raise ValueError("first message must be a session handshake")
    if any(len(message.encode("utf-8")) > 1_048_576 for message in encoded):
        raise ValueError("message exceeds the transport byte limit")
    served = asyncio.Event()

    async def publish(connection: ServerConnection) -> None:
        for message in encoded:
            await connection.send(message)
            if delay_seconds:
                await asyncio.sleep(delay_seconds)
        await connection.close(1000, "session complete")
        served.set()

    async with serve(publish, host, port, compression=None, max_size=1_048_576, max_queue=16) as server:
        if ready is not None:
            ready(host, server.sockets[0].getsockname()[1])
        await asyncio.wait_for(served.wait(), timeout=300)
