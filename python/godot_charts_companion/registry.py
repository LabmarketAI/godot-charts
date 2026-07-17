"""Explicit adapter registry; registration never imports or executes user plugins."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

from .contracts import CompatibilityReport, PlotRequest

Inspector = Callable[[PlotRequest], CompatibilityReport]
Converter = Callable[[PlotRequest], dict]


@dataclass(frozen=True)
class Adapter:
    name: str
    inspect: Inspector
    convert: Converter


class AdapterRegistry:
    def __init__(self) -> None:
        self._adapters: dict[str, Adapter] = {}

    def register(self, adapter: Adapter) -> None:
        if adapter.name in self._adapters:
            raise ValueError(f"adapter is already registered: {adapter.name}")
        self._adapters[adapter.name] = adapter

    def names(self) -> tuple[str, ...]:
        return tuple(sorted(self._adapters))

    def compatibility(self, request: PlotRequest) -> tuple[CompatibilityReport, ...]:
        return tuple(self._adapters[name].inspect(request) for name in self.names())

    def convert(self, request: PlotRequest, *, adapter: str | None = None) -> dict:
        candidates = [self._adapters[adapter]] if adapter else [self._adapters[name] for name in self.names()]
        for candidate in candidates:
            report = candidate.inspect(request)
            if report.compatible:
                return candidate.convert(request)
        raise ValueError("no compatible adapter: " + "; ".join(
            f"{report.adapter}={report.status}" for report in self.compatibility(request)
        ))
