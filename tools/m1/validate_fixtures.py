#!/usr/bin/env python3
"""Validate M1 schemas and every generated message fixture."""

from __future__ import annotations

import json
from pathlib import Path

from jsonschema import Draft202012Validator
from referencing import Registry, Resource


ROOT = Path(__file__).resolve().parents[2]
SCHEMAS = ROOT / "addons" / "godot-charts" / "schemas" / "m1"
FIXTURES = ROOT / "tests" / "m1" / "fixtures"
SCHEMA_BY_PREFIX = {
    "godot-charts/session-handshake/": "session-handshake.schema.json",
    "godot-charts/plot-message/": "plot-message.schema.json",
    "godot-charts/table-result/": "table-result.schema.json",
    "godot-charts/selection/": "selection.schema.json",
}


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    schema_documents = {path.name: load(path) for path in SCHEMAS.glob("*.schema.json")}
    registry = Registry()
    for name, document in schema_documents.items():
        registry = registry.with_resource(name, Resource.from_contents(document))
        registry = registry.with_resource(document["$id"], Resource.from_contents(document))

    validated = 0
    for path in sorted(FIXTURES.glob("*.json")):
        document = load(path)
        if document.get("schema") == "godot-charts/replay-manifest/1.0":
            continue
        schema_name = next(
            (name for prefix, name in SCHEMA_BY_PREFIX.items() if document.get("schema", "").startswith(prefix)),
            None,
        )
        if schema_name is None:
            raise ValueError(f"No schema registered for {path}: {document.get('schema')}")
        errors = sorted(
            Draft202012Validator(schema_documents[schema_name], registry=registry).iter_errors(document),
            key=lambda error: list(error.absolute_path),
        )
        if errors:
            formatted = "\n".join(f"{path}: /{'/'.join(map(str, error.absolute_path))}: {error.message}" for error in errors)
            raise ValueError(formatted)
        validated += 1
    print(f"Validated {validated} M1 message fixtures against Draft 2020-12 schemas.")


if __name__ == "__main__":
    main()
