#!/usr/bin/env python3
"""Validate official GLB-backed chart assets.

This intentionally avoids third-party packages so it can run in CI and local
developer shells before Godot imports the assets.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = ROOT / "addons" / "godot-charts" / "assets" / "visual" / "glb" / "asset_pack_manifest.json"
GLB_MAGIC = 0x46546C67
JSON_CHUNK = 0x4E4F534A


class ValidationError(Exception):
    pass


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args()

    try:
        manifest = _load_json(args.manifest)
        _validate_manifest(args.manifest, manifest)
    except ValidationError as exc:
        print(f"GLB asset validation failed: {exc}", file=sys.stderr)
        return 1

    print(f"GLB asset validation passed: {args.manifest}")
    return 0


def _load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise ValidationError(f"manifest not found: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValidationError(f"manifest is not valid JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise ValidationError("manifest top-level value must be an object")
    return value


def _validate_manifest(manifest_path: Path, manifest: dict[str, Any]) -> None:
    if manifest.get("schema") != "godot-charts/visual-asset-pack/1.0":
        raise ValidationError("unsupported or missing manifest schema")
    roles = manifest.get("roles")
    if not isinstance(roles, dict) or not roles:
        raise ValidationError("manifest must define at least one role")

    for role, entry in roles.items():
        if not isinstance(entry, dict):
            raise ValidationError(f"{role}: role entry must be an object")
        asset_path = _resolve_res_path(entry.get("asset"))
        gltf = _load_glb_json(asset_path)
        _validate_common_role(role, entry, gltf, asset_path)
        if role == "control/handle_linear":
            _validate_control_handle_linear(entry, gltf)


def _resolve_res_path(value: Any) -> Path:
    if not isinstance(value, str) or not value.startswith("res://"):
        raise ValidationError(f"asset path must be a res:// path, got {value!r}")
    path = ROOT / value.removeprefix("res://")
    if not path.exists():
        raise ValidationError(f"asset file not found: {path}")
    return path


def _load_glb_json(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValidationError(f"{path}: file is too small to be a GLB")
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != GLB_MAGIC:
        raise ValidationError(f"{path}: invalid GLB magic")
    if version != 2:
        raise ValidationError(f"{path}: expected GLB version 2, got {version}")
    if length != len(data):
        raise ValidationError(f"{path}: GLB length header does not match file size")

    offset = 12
    while offset + 8 <= len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset : offset + chunk_length]
        offset += chunk_length
        if chunk_type == JSON_CHUNK:
            try:
                value = json.loads(chunk.decode("utf-8").rstrip("\x00 "))
            except json.JSONDecodeError as exc:
                raise ValidationError(f"{path}: invalid glTF JSON chunk: {exc}") from exc
            if not isinstance(value, dict):
                raise ValidationError(f"{path}: glTF JSON chunk must be an object")
            return value
    raise ValidationError(f"{path}: missing glTF JSON chunk")


def _validate_common_role(role: str, entry: dict[str, Any], gltf: dict[str, Any], asset_path: Path) -> None:
    nodes = _nodes_by_name(gltf)
    mesh_nodes = _mesh_nodes_by_name(gltf)

    for key in ["pivot", "forward", "up", "fallback"]:
        if not entry.get(key):
            raise ValidationError(f"{role}: missing manifest field {key}")

    lods = entry.get("lods")
    if not isinstance(lods, dict) or "LOD0" not in lods:
        raise ValidationError(f"{role}: missing LOD0 list")
    for lod_name, object_names in lods.items():
        if not isinstance(object_names, list) or not object_names:
            raise ValidationError(f"{role}: {lod_name} must list at least one object")
        for object_name in object_names:
            if object_name not in mesh_nodes:
                raise ValidationError(f"{role}: {lod_name} object is missing or not visible mesh: {object_name}")

    collision = entry.get("collision")
    if not isinstance(collision, dict) or collision.get("object") not in mesh_nodes:
        raise ValidationError(f"{role}: collision object is missing or not a mesh")

    sockets = entry.get("sockets")
    if not isinstance(sockets, dict) or not sockets:
        raise ValidationError(f"{role}: missing sockets")
    for socket_name, object_name in sockets.items():
        if object_name not in nodes:
            raise ValidationError(f"{role}: socket {socket_name} references missing node {object_name}")

    if _duplicate_names(gltf.get("nodes", [])):
        raise ValidationError(f"{role}: GLB has duplicate node names")
    if not gltf.get("materials"):
        raise ValidationError(f"{role}: GLB has no materials")
    _validate_materials(role, entry, gltf)
    _validate_mesh_primitives(role, entry, gltf, mesh_nodes)
    _validate_runtime_export_names(role, nodes)


def _validate_control_handle_linear(entry: dict[str, Any], gltf: dict[str, Any]) -> None:
    nodes = _nodes_by_name(gltf)
    mesh_nodes = _mesh_nodes_by_name(gltf)
    expected_cross = {
        "role__control_handle_linear__axis_alignment_inset_x_lod0",
        "role__control_handle_linear__axis_alignment_inset_y_lod0",
    }
    actual_cross = {name for name in mesh_nodes if "axis_alignment_inset" in name}
    if actual_cross != expected_cross:
        raise ValidationError(
            "control/handle_linear: top axis cue must be exactly two visible "
            f"axis_alignment_inset meshes, got {sorted(actual_cross)}"
        )

    forbidden_visible_terms = ("warning", "error", "status", "stripe")
    visible_state_overlays = [
        name
        for name in mesh_nodes
        if any(term in name.lower() for term in forbidden_visible_terms)
    ]
    if visible_state_overlays:
        raise ValidationError(
            "control/handle_linear: default asset must not export visible stacked "
            f"state overlays: {visible_state_overlays}"
        )

    sockets = entry.get("sockets", {})
    if "warning_stripe" in sockets or "error_stripe" in sockets:
        raise ValidationError("control/handle_linear: warning/error stripe sockets are deprecated")
    for socket_name in ["warning_state", "error_state"]:
        node_name = sockets.get(socket_name)
        if not node_name:
            raise ValidationError(f"control/handle_linear: missing {socket_name} socket")
        if node_name in mesh_nodes:
            raise ValidationError(f"control/handle_linear: {socket_name} must be metadata/socket only, not a mesh")

    x_node = nodes["role__control_handle_linear__axis_alignment_inset_x_lod0"]
    y_node = nodes["role__control_handle_linear__axis_alignment_inset_y_lod0"]
    if _node_origin(x_node) != _node_origin(y_node):
        raise ValidationError("control/handle_linear: top cross bars must share the same origin/center plane")


def _validate_materials(role: str, entry: dict[str, Any], gltf: dict[str, Any]) -> None:
    declared_slots = entry.get("material_slots")
    if not isinstance(declared_slots, list) or not declared_slots:
        raise ValidationError(f"{role}: manifest must declare semantic material_slots")
    declared = {slot for slot in declared_slots if isinstance(slot, str)}
    if len(declared) != len(declared_slots):
        raise ValidationError(f"{role}: material_slots must contain only strings")

    for index, material in enumerate(gltf.get("materials", [])):
        name = material.get("name") if isinstance(material, dict) else None
        if name not in declared:
            raise ValidationError(f"{role}: exported material is not declared as semantic slot: {name!r}")
        if material.get("alphaMode", "OPAQUE") != "OPAQUE" and name != "collision_hidden":
            raise ValidationError(f"{role}: material {name!r} uses alpha; WebXR P0 assets must stay opaque")


def _validate_mesh_primitives(
    role: str,
    entry: dict[str, Any],
    gltf: dict[str, Any],
    mesh_nodes: dict[str, dict[str, Any]],
) -> None:
    accessors = gltf.get("accessors", [])
    meshes = gltf.get("meshes", [])
    lods = entry.get("lods", {})
    material_count = len(gltf.get("materials", []))
    declared_slot_count = len(entry.get("material_slots", []))
    if material_count > declared_slot_count:
        raise ValidationError(
            f"{role}: exported material count {material_count} exceeds declared semantic slots {declared_slot_count}"
        )

    for node_name, node in mesh_nodes.items():
        mesh_index = node.get("mesh")
        if not isinstance(mesh_index, int) or mesh_index >= len(meshes):
            raise ValidationError(f"{role}: node {node_name} references invalid mesh index")
        mesh = meshes[mesh_index]
        for primitive in mesh.get("primitives", []):
            attributes = primitive.get("attributes", {})
            if "NORMAL" not in attributes:
                raise ValidationError(f"{role}: mesh node {node_name} is missing NORMAL attributes")
            if "POSITION" not in attributes:
                raise ValidationError(f"{role}: mesh node {node_name} is missing POSITION attributes")
            material_index = primitive.get("material")
            if not isinstance(material_index, int):
                raise ValidationError(f"{role}: mesh node {node_name} has a primitive without material")

    lod_triangle_counts = {
        lod_name: _triangle_count_for_nodes(node_names, mesh_nodes, meshes, accessors)
        for lod_name, node_names in lods.items()
    }
    performance_tiers = entry.get("performance_tiers")
    if not isinstance(performance_tiers, dict) or not performance_tiers:
        raise ValidationError(f"{role}: missing performance_tiers")
    for tier_name, tier in performance_tiers.items():
        if not isinstance(tier, dict) or not isinstance(tier.get("max_triangles"), int):
            raise ValidationError(f"{role}: performance tier {tier_name} must declare max_triangles")
        lod_name = tier.get("lod")
        if lod_name not in lod_triangle_counts:
            raise ValidationError(f"{role}: performance tier {tier_name} must declare a valid lod")
        triangle_count = lod_triangle_counts[lod_name]
        if triangle_count > tier["max_triangles"]:
            raise ValidationError(
                f"{role}: {lod_name} triangle count {triangle_count} exceeds {tier_name} budget {tier['max_triangles']}"
            )
        if tier.get("shadows", False):
            raise ValidationError(f"{role}: performance tier {tier_name} must not require shadows")


def _validate_runtime_export_names(role: str, nodes: dict[str, dict[str, Any]]) -> None:
    forbidden_terms = ("concept", "draft", "reference", "preview", "camera", "light")
    offenders = [
        name
        for name in nodes
        if any(term in name.lower() for term in forbidden_terms)
    ]
    if offenders:
        raise ValidationError(f"{role}: runtime GLB contains non-runtime authoring nodes: {offenders}")


def _triangle_count_for_nodes(
    node_names: Any,
    mesh_nodes: dict[str, dict[str, Any]],
    meshes: list[Any],
    accessors: list[Any],
) -> int:
    if not isinstance(node_names, list):
        return 0
    total = 0
    for node_name in node_names:
        node = mesh_nodes.get(node_name)
        if node is None:
            continue
        mesh = meshes[node["mesh"]]
        for primitive in mesh.get("primitives", []):
            mode = primitive.get("mode", 4)
            if mode != 4:
                raise ValidationError(f"{node_name}: only triangle primitive mode is supported")
            if isinstance(primitive.get("indices"), int):
                total += _accessor_count(accessors, primitive["indices"]) // 3
            else:
                position_accessor = primitive.get("attributes", {}).get("POSITION")
                total += _accessor_count(accessors, position_accessor) // 3
    return total


def _accessor_count(accessors: list[Any], index: Any) -> int:
    if not isinstance(index, int) or index >= len(accessors):
        return 0
    accessor = accessors[index]
    if not isinstance(accessor, dict):
        return 0
    return int(accessor.get("count", 0))


def _nodes_by_name(gltf: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for node in gltf.get("nodes", []):
        if isinstance(node, dict) and isinstance(node.get("name"), str):
            result[node["name"]] = node
    return result


def _mesh_nodes_by_name(gltf: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        name: node
        for name, node in _nodes_by_name(gltf).items()
        if isinstance(node.get("mesh"), int)
    }


def _duplicate_names(nodes: Any) -> list[str]:
    if not isinstance(nodes, list):
        return []
    seen: set[str] = set()
    duplicates: list[str] = []
    for node in nodes:
        if not isinstance(node, dict) or not isinstance(node.get("name"), str):
            continue
        name = node["name"]
        if name in seen:
            duplicates.append(name)
        seen.add(name)
    return duplicates


def _node_origin(node: dict[str, Any]) -> tuple[float, float, float]:
    if isinstance(node.get("translation"), list) and len(node["translation"]) >= 3:
        return tuple(round(float(value), 5) for value in node["translation"][:3])
    if isinstance(node.get("matrix"), list) and len(node["matrix"]) >= 15:
        return (
            round(float(node["matrix"][12]), 5),
            round(float(node["matrix"][13]), 5),
            round(float(node["matrix"][14]), 5),
        )
    return (0.0, 0.0, 0.0)


if __name__ == "__main__":
    raise SystemExit(main())
