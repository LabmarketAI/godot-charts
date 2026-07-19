#!/usr/bin/env python3
"""Create the production control/handle_linear GLB asset.

Run with:
    blender --background --python tools/assets/blender/create_control_handle_linear_asset.py
"""

from __future__ import annotations

import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
SOURCE_BLEND = ROOT / "tools" / "assets" / "blender" / "generated" / "control_handle_linear.blend"
OUTPUT_GLB = ROOT / "addons" / "godot-charts" / "assets" / "visual" / "glb" / "control_handle_linear.glb"
MANIFEST = ROOT / "addons" / "godot-charts" / "assets" / "visual" / "glb" / "asset_pack_manifest.json"

SEMANTIC_MATERIALS = {
    "control_body": (0.17, 0.21, 0.23, 1.0),
    "control_focus": (0.20, 0.84, 0.92, 1.0),
    "control_active": (0.95, 0.55, 0.18, 1.0),
    "status_warning": (0.95, 0.72, 0.18, 1.0),
    "status_error": (0.90, 0.18, 0.22, 1.0),
    "collision_hidden": (0.95, 0.20, 0.80, 0.22),
}


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)


def collection(name: str) -> bpy.types.Collection:
    result = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(result)
    return result


def link_to(target: bpy.types.Collection, obj: bpy.types.Object) -> None:
    for existing in list(obj.users_collection):
        existing.objects.unlink(obj)
    target.objects.link(obj)


def make_material(name: str, color: tuple[float, float, float, float], *, roughness: float = 0.82, alpha: float = 1.0, emission: bool = False) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_fake_user = True
    mat.use_nodes = True
    mat.diffuse_color = (color[0], color[1], color[2], alpha)
    mat["semantic_slot"] = name
    mat["metallic"] = 0.0
    mat["roughness"] = roughness
    mat["webxr_safe"] = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], alpha)
        bsdf.inputs["Metallic"].default_value = 0.0
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Alpha"].default_value = alpha
        if emission:
            bsdf.inputs["Emission Color"].default_value = (color[0], color[1], color[2], 1.0)
            bsdf.inputs["Emission Strength"].default_value = 0.28
    if alpha < 1.0:
        mat.blend_method = "BLEND"
        mat.use_screen_refraction = False
        mat.show_transparent_back = True
    return mat


def smooth_mesh(obj: bpy.types.Object) -> None:
    for polygon in obj.data.polygons:
        polygon.use_smooth = True


def add_weighted_bevel(obj: bpy.types.Object, width: float, segments: int) -> None:
    bevel = obj.modifiers.new("production_bevel_hardened_normals", "BEVEL")
    bevel.width = width
    bevel.segments = segments
    bevel.affect = "EDGES"
    bevel.harden_normals = True
    weighted = obj.modifiers.new("production_weighted_normals", "WEIGHTED_NORMAL")
    weighted.keep_sharp = True


def add_cylinder(name: str, coll: bpy.types.Collection, mat: bpy.types.Material, *, radius: float, depth: float, vertices: int) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=(0, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.data.materials.append(mat)
    smooth_mesh(obj)
    add_weighted_bevel(obj, 0.0042, 3)
    link_to(coll, obj)
    return obj


def add_torus(name: str, coll: bpy.types.Collection, mat: bpy.types.Material, *, major_radius: float, minor_radius: float, z: float = 0.0, major_segments: int = 96, minor_segments: int = 10) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(major_segments=major_segments, minor_segments=minor_segments, major_radius=major_radius, minor_radius=minor_radius, location=(0, 0, z))
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.data.materials.append(mat)
    smooth_mesh(obj)
    link_to(coll, obj)
    return obj


def add_uv_sphere(name: str, coll: bpy.types.Collection, mat: bpy.types.Material, *, radius: float) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=radius, location=(0, 0, 0))
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.data.materials.append(mat)
    smooth_mesh(obj)
    obj.display_type = "WIRE"
    obj.hide_render = True
    link_to(coll, obj)
    return obj


def add_cube(name: str, coll: bpy.types.Collection, mat: bpy.types.Material, *, location: tuple[float, float, float], scale: tuple[float, float, float]) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    add_weighted_bevel(obj, 0.0012, 1)
    link_to(coll, obj)
    return obj


def add_empty(name: str, coll: bpy.types.Collection, *, display_size: float = 0.06) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = display_size
    coll.objects.link(obj)
    return obj


def set_role_metadata(obj: bpy.types.Object, *, role: str, lod: str | None = None) -> None:
    obj["role"] = role
    obj["pivot"] = "center"
    obj["forward"] = "+Z"
    obj["up"] = "+Y"
    obj["visible_body_diameter_m"] = 0.10
    obj["visible_body_thickness_m"] = 0.035
    obj["collision_diameter_m"] = 0.16
    obj["theme_target"] = "WebXR Dark Instrument"
    obj["fallback_role"] = "fallback/minimal_handle"
    if lod is not None:
        obj["lod"] = lod


def build_asset() -> None:
    clear_scene()
    bpy.context.preferences.filepaths.save_version = 0
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    if "BLENDER_EEVEE_NEXT" in scene.render.bl_rna.properties["engine"].enum_items:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    else:
        scene.render.engine = "BLENDER_EEVEE"
    scene["godot_charts_asset_schema"] = "godot-charts/blender-asset/1.0"
    scene["role"] = "control/handle_linear"
    scene["source_prompt"] = "openspec/changes/chart-asset-production-pipeline/prompts/p0/control-handle-linear.md"

    collections = {
        "LOD0": collection("LOD0"),
        "LOD1": collection("LOD1"),
        "COLLISION": collection("COLLISION"),
        "SOCKETS": collection("SOCKETS"),
        "PREVIEW": collection("PREVIEW"),
    }

    materials = {
        name: make_material(
            name,
            color,
            roughness=0.76 if name.startswith("control") else 0.86,
            alpha=color[3],
            emission=name in {"control_focus", "control_active", "status_warning", "status_error"},
        )
        for name, color in SEMANTIC_MATERIALS.items()
    }

    body = add_cylinder(
        "role__control_handle_linear__body_lod0",
        collections["LOD0"],
        materials["control_body"],
        radius=0.05,
        depth=0.035,
        vertices=48,
    )
    set_role_metadata(body, role="control/handle_linear", lod="LOD0")

    groove = add_torus(
        "role__control_handle_linear__grip_groove_lod0",
        collections["LOD0"],
        materials["control_active"],
        major_radius=0.0515,
        minor_radius=0.0024,
        major_segments=64,
        minor_segments=6,
    )
    set_role_metadata(groove, role="control/handle_linear", lod="LOD0")
    groove["state_cue"] = "active_grip_groove"

    axis_inset_x = add_cube(
        "role__control_handle_linear__axis_alignment_inset_x_lod0",
        collections["LOD0"],
        materials["control_focus"],
        location=(0.0, 0.0, 0.019),
        scale=(0.074, 0.009, 0.003),
    )
    set_role_metadata(axis_inset_x, role="control/handle_linear", lod="LOD0")
    axis_inset_x["state_cue"] = "axis_alignment_non_color"

    axis_inset_y = add_cube(
        "role__control_handle_linear__axis_alignment_inset_y_lod0",
        collections["LOD0"],
        materials["control_focus"],
        location=(0.0, 0.0, 0.019),
        scale=(0.009, 0.074, 0.003),
    )
    set_role_metadata(axis_inset_y, role="control/handle_linear", lod="LOD0")
    axis_inset_y["state_cue"] = "axis_alignment_non_color"

    low = add_cylinder(
        "lod__control_handle_linear__body_lod1",
        collections["LOD1"],
        materials["control_body"],
        radius=0.05,
        depth=0.035,
        vertices=24,
    )
    set_role_metadata(low, role="control/handle_linear", lod="LOD1")

    low_groove = add_torus(
        "lod__control_handle_linear__grip_groove_lod1",
        collections["LOD1"],
        materials["control_active"],
        major_radius=0.0515,
        minor_radius=0.0024,
        major_segments=32,
        minor_segments=5,
    )
    set_role_metadata(low_groove, role="control/handle_linear", lod="LOD1")
    low_groove["state_cue"] = "active_grip_groove"

    collision = add_uv_sphere(
        "collision__control_handle_linear__sphere_0_16m",
        collections["COLLISION"],
        materials["collision_hidden"],
        radius=0.08,
    )
    set_role_metadata(collision, role="control/handle_linear")
    collision["collision_proxy"] = "sphere"
    collision["diameter_m"] = 0.16

    focus_socket = add_torus(
        "socket__control_handle_linear__focus_ring_0_14m",
        collections["SOCKETS"],
        materials["control_focus"],
        major_radius=0.07,
        minor_radius=0.0035,
        z=0.021,
        major_segments=64,
        minor_segments=6,
    )
    set_role_metadata(focus_socket, role="control/handle_linear")
    focus_socket["socket"] = "control_focus"
    focus_socket["semantic_note"] = "Socket preview for control/focus_ring; provider may hide or replace at runtime."

    warning_socket = add_empty("socket__control_handle_linear__warning_state", collections["SOCKETS"], display_size=0.035)
    warning_socket.location = (0.0, 0.0, 0.024)
    set_role_metadata(warning_socket, role="control/handle_linear")
    warning_socket["socket"] = "status_warning"
    warning_socket["semantic_note"] = "Runtime state socket only; no visible warning geometry is exported."

    error_socket = add_empty("socket__control_handle_linear__error_state", collections["SOCKETS"], display_size=0.035)
    error_socket.location = (0.0, 0.0, 0.024)
    set_role_metadata(error_socket, role="control/handle_linear")
    error_socket["socket"] = "status_error"
    error_socket["semantic_note"] = "Runtime state socket only; no visible error geometry is exported."

    origin = add_empty("origin__control_handle_linear__center", collections["SOCKETS"], display_size=0.08)
    set_role_metadata(origin, role="control/handle_linear")
    origin["socket"] = "pivot_center"

    bpy.ops.object.select_all(action="DESELECT")
    export_objects = []
    for coll_name in ["LOD0", "LOD1", "COLLISION", "SOCKETS"]:
        export_objects.extend(collections[coll_name].objects)
    for obj in export_objects:
        obj.select_set(True)

    SOURCE_BLEND.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_GLB.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_BLEND))
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT_GLB),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_normals=True,
        export_tangents=False,
        export_extras=True,
        export_cameras=False,
        export_lights=False,
    )


def write_manifest() -> None:
    data = {
        "schema": "godot-charts/visual-asset-pack/1.0",
        "id": "core-glb-instrument-p0",
        "name": "Core GLB Instrument P0",
        "license": "MIT",
        "source": "project-owned Blender-generated GLB assets",
        "roles": {
            "control/handle_linear": {
                "asset": "res://addons/godot-charts/assets/visual/glb/control_handle_linear.glb",
                "source_blend": "tools/assets/blender/generated/control_handle_linear.blend",
                "source_prompt": "openspec/changes/chart-asset-production-pipeline/prompts/p0/control-handle-linear.md",
                "pivot": "center",
                "forward": "+Z",
                "up": "+Y",
                "visible_body": {"diameter_m": 0.10, "thickness_m": 0.035},
                "collision": {"type": "sphere", "diameter_m": 0.16, "object": "collision__control_handle_linear__sphere_0_16m"},
                "lods": {
                    "LOD0": [
                        "role__control_handle_linear__body_lod0",
                        "role__control_handle_linear__grip_groove_lod0",
                        "role__control_handle_linear__axis_alignment_inset_x_lod0",
                        "role__control_handle_linear__axis_alignment_inset_y_lod0",
                    ],
                    "LOD1": ["lod__control_handle_linear__body_lod1", "lod__control_handle_linear__grip_groove_lod1"],
                },
                "sockets": {
                    "focus_ring": "socket__control_handle_linear__focus_ring_0_14m",
                    "warning_state": "socket__control_handle_linear__warning_state",
                    "error_state": "socket__control_handle_linear__error_state",
                    "pivot_center": "origin__control_handle_linear__center",
                },
                "material_slots": [
                    "control_body",
                    "control_focus",
                    "control_active",
                    "status_warning",
                    "status_error",
                    "collision_hidden",
                ],
                "states": ["normal", "hover", "focus", "active", "disabled", "warning", "error"],
                "inputs": ["controller_ray", "direct_grab", "mouse_pointer", "keyboard_focus"],
                "accessibility": {
                    "non_color_cues": ["focus_ring_socket", "active_grip_groove", "axis_alignment_inset"],
                    "minimum_non_text_contrast": "3:1 through theme tokens",
                    "gaze_dwell_required": False,
                    "reduced_motion_fallback": True,
                },
                "performance_tiers": {
                    "desktop": {"lod": "LOD0", "max_triangles": 3000, "shadows": False},
                    "native_xr": {"lod": "LOD0", "max_triangles": 1800, "shadows": False},
                    "webxr": {"lod": "LOD1", "max_triangles": 900, "shadows": False, "reduced_motion": True},
                },
                "fallback": "fallback/minimal_handle",
            }
        },
    }
    MANIFEST.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    build_asset()
    write_manifest()
    print(f"Created {SOURCE_BLEND}")
    print(f"Created {OUTPUT_GLB}")
    print(f"Created {MANIFEST}")
