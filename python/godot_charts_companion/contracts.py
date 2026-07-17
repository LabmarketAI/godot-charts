"""Small backend-neutral contracts shared by companion adapters."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from hashlib import sha256
import json
import re
from typing import Any

IDENTIFIER_PART = re.compile(r"[^A-Za-z0-9._:-]+")


@dataclass(frozen=True)
class CompatibilityReport:
    adapter: str
    status: str
    supported: tuple[str, ...] = ()
    approximated: tuple[str, ...] = ()
    rejected: tuple[str, ...] = ()
    diagnostics: tuple[dict[str, Any], ...] = ()

    @property
    def compatible(self) -> bool:
        return self.status in {"supported", "approximated"}

    def to_dictionary(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class PlotRequest:
    source: Any
    data: Any
    options: dict[str, Any] = field(default_factory=dict)


def deterministic_id(prefix: str, *identity_parts: str) -> str:
    """Create a stable protocol ID without Python's process-randomized hash()."""
    if not identity_parts or any(not isinstance(part, str) or not part for part in identity_parts):
        raise ValueError("deterministic IDs require non-empty string identity parts")
    safe_prefix = IDENTIFIER_PART.sub("-", prefix).strip("-.")
    if not safe_prefix:
        raise ValueError("deterministic ID prefix must contain identifier characters")
    canonical = json.dumps(identity_parts, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return f"{safe_prefix}-{sha256(canonical).hexdigest()[:20]}"
