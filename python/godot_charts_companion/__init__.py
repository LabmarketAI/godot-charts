"""Public companion API for supported analytical objects."""

__version__ = "0.1.0"

from .contracts import CompatibilityReport, PlotRequest, deterministic_id
from .matplotlib_adapter import Scatter3DMapping, matplotlib_scatter_adapter, matplotlib_scatter_message
from .publisher import handshake_message, serve_messages
from .registry import Adapter, AdapterRegistry

__all__ = [
    "Adapter",
    "AdapterRegistry",
    "CompatibilityReport",
    "PlotRequest",
    "Scatter3DMapping",
    "deterministic_id",
    "handshake_message",
    "matplotlib_scatter_message",
    "matplotlib_scatter_adapter",
    "serve_messages",
]
