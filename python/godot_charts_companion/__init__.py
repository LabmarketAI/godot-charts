"""Public companion API for supported analytical objects."""

__version__ = "0.1.0"

from .matplotlib_adapter import Scatter3DMapping, matplotlib_scatter_message
from .publisher import handshake_message, serve_messages

__all__ = [
    "Scatter3DMapping",
    "handshake_message",
    "matplotlib_scatter_message",
    "serve_messages",
]
