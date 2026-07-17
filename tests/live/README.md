# Live WebSocket transport test

This suite publishes the canonical M1 replay manifest from a localhost Python WebSocket server and consumes it with standard Godot's built-in `WebSocketPeer`. It verifies that the optional network adapter produces the same protocol, session, scatter, table, duplicate, revision, and selection results as in-process recorded replay.

The server binds to `127.0.0.1`, chooses an ephemeral port, disables compression, bounds message and queue sizes, serves one client, and exits. Its pinned Python dependency is test-only; the packaged addon has no Python requirement.
