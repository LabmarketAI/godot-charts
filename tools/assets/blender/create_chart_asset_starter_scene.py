#!/usr/bin/env python3
"""Create the Godot Charts Blender starter scene.

Run with:
    blender --background --python tools/assets/blender/create_chart_asset_starter_scene.py
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
OUTPUT = ROOT / "tools" / "assets" / "blender" / "chart_asset_starter.blend"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)


def create_collection(name: str) -> bpy.types.Collection:
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def link_to(collection: bpy.types.Collection, obj: bpy.types.Object) -> None:
    for existing in list(obj.users_collection):
        existing.objects.unlink(obj)
    collection.objects.link(obj)


def material(name: str, color: tuple[float, float, float, float], *, metallic: float = 0.0, roughness: float = 0.85, alpha: float = 1.0, emission: tuple[float, float, float] | None = None) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_fake_user = True
    mat.use_nodes = True
    mat.diffuse_color = (color[0], color[1], color[2], alpha)
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], alpha)
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Alpha"].default_value = alpha
        if emission is not None:
            bsdf.inputs["Emission Color"].default_value = (emission[0], emission[1], emission[2], 1.0)
            bsdf.inputs["Emission Strength"].default_value = 0.35
    mat["semantic_slot"] = name
    return mat


def add_cube(name: str, location: tuple[float, float, float], scale: tuple[float, float, float], mat: bpy.types.Material, collection: bpy.types.Collection) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    link_to(collection, obj)
    return obj


def add_uv_sphere(name: str, location: tuple[float, float, float], radius: float, mat: bpy.types.Material, collection: bpy.types.Collection, *, segments: int = 48, rings: int = 24) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    link_to(collection, obj)
    return obj


def add_cylinder(name: str, location: tuple[float, float, float], radius: float, depth: float, mat: bpy.types.Material, collection: bpy.types.Collection, *, vertices: int = 48) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    bevel = obj.modifiers.new("starter_small_bevel", "BEVEL")
    bevel.width = 0.004
    bevel.segments = 4
    bevel.affect = "EDGES"
    bevel.harden_normals = True
    weighted = obj.modifiers.new("starter_weighted_normals", "WEIGHTED_NORMAL")
    weighted.keep_sharp = True
    link_to(collection, obj)
    return obj


def add_torus(name: str, location: tuple[float, float, float], major_radius: float, minor_radius: float, mat: bpy.types.Material, collection: bpy.types.Collection) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(major_segments=96, minor_segments=12, major_radius=major_radius, minor_radius=minor_radius, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    link_to(collection, obj)
    return obj


def add_empty(name: str, location: tuple[float, float, float], collection: bpy.types.Collection, *, display_size: float = 0.08) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = display_size
    obj.location = location
    collection.objects.link(obj)
    return obj


def add_label(name: str, text: str, location: tuple[float, float, float], collection: bpy.types.Collection, size: float = 0.05) -> bpy.types.Object:
    curve = bpy.data.curves.new(name, "FONT")
    curve.body = text
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.size = size
    obj = bpy.data.objects.new(name, curve)
    obj.location = location
    collection.objects.link(obj)
    return obj


def build_scene() -> None:
    clear_scene()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    if "BLENDER_EEVEE_NEXT" in scene.render.bl_rna.properties["engine"].enum_items:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    else:
        scene.render.engine = "BLENDER_EEVEE"
    scene["godot_charts_starter_schema"] = "godot-charts/blender-starter/1.0"
    scene["world_units"] = "1 Blender unit = 1 meter = 1 Godot unit"
    scene["runtime_export_note"] = "Export selected role objects only. Exclude REFERENCES, cameras, lights, concept geometry, and authoring labels."
    bpy.context.preferences.filepaths.save_version = 0

    collections = {
        "LOD0": create_collection("LOD0"),
        "LOD1": create_collection("LOD1"),
        "COLLISION": create_collection("COLLISION"),
        "SOCKETS": create_collection("SOCKETS"),
        "PREVIEW": create_collection("PREVIEW"),
        "REFERENCES": create_collection("REFERENCES"),
    }

    mats = {
        "control_body": material("control_body", (0.18, 0.22, 0.24, 1.0), roughness=0.82),
        "control_focus": material("control_focus", (0.22, 0.86, 0.92, 1.0), roughness=0.7, emission=(0.12, 0.55, 0.6)),
        "control_active": material("control_active", (0.95, 0.58, 0.20, 1.0), roughness=0.75),
        "status_warning": material("status_warning", (0.95, 0.72, 0.18, 1.0), roughness=0.8),
        "status_error": material("status_error", (0.90, 0.18, 0.22, 1.0), roughness=0.8),
        "data_matte": material("data_matte", (0.16, 0.45, 0.88, 1.0), roughness=0.95),
        "data_selected_outline": material("data_selected_outline", (0.05, 0.10, 0.16, 1.0), roughness=0.9),
        "structure_quiet": material("structure_quiet", (0.48, 0.55, 0.58, 1.0), roughness=0.95),
        "guide_panel": material("guide_panel", (0.82, 0.86, 0.86, 0.82), roughness=0.9, alpha=0.82),
        "collision_hidden": material("collision_hidden", (0.95, 0.20, 0.80, 0.24), roughness=1.0, alpha=0.24),
        "reference": material("reference", (0.65, 0.68, 0.70, 0.45), roughness=1.0, alpha=0.45),
    }

    # Reference scale guides.
    add_cylinder("reference__human_height_1_70m", (-0.9, -0.85, 0.85), 0.12, 1.7, mats["reference"], collections["REFERENCES"], vertices=32)
    add_cube("reference__chart_frame_1_20m_x_0_80m", (0.0, -0.85, 0.4), (1.2, 0.025, 0.8), mats["reference"], collections["REFERENCES"])
    add_torus("reference__direct_reach_ring_radius_0_80m", (0.0, 0.0, 0.01), 0.8, 0.004, mats["reference"], collections["REFERENCES"])
    add_uv_sphere("reference__handle_body_0_10m", (0.85, -0.85, 0.1), 0.05, mats["reference"], collections["REFERENCES"], segments=32, rings=16)
    add_label("preview__scale_note", "Scale: 1 unit = 1 meter | frame 1.2m | handle 10cm | collision 16cm", (0.0, -1.15, 1.05), collections["PREVIEW"], size=0.045)

    # Axis orientation preview.
    add_cube("preview__axis_x_1m", (0.0, 0.95, 0.02), (1.0, 0.01, 0.01), mats["structure_quiet"], collections["PREVIEW"])
    add_cube("preview__axis_y_1m", (-0.5, 1.45, 0.02), (0.01, 1.0, 0.01), mats["structure_quiet"], collections["PREVIEW"])
    add_cube("preview__axis_z_1m", (-0.5, 0.95, 0.52), (0.01, 0.01, 1.0), mats["structure_quiet"], collections["PREVIEW"])

    # Example P0 handle using the prompt conventions.
    body = add_cylinder("role__control_handle_linear__body_lod0", (0.0, 0.0, 0.08), 0.05, 0.035, mats["control_body"], collections["LOD0"], vertices=64)
    body.rotation_euler[0] = math.radians(90.0)
    body["role"] = "control/handle_linear"
    body["pivot"] = "center"
    body["visible_body_diameter_m"] = 0.10
    body["intended_collision_diameter_m"] = 0.16
    body["theme_target"] = "WebXR Dark Instrument"

    groove = add_torus("role__control_handle_linear__grip_groove_lod0", (0.0, 0.0, 0.08), 0.051, 0.003, mats["control_active"], collections["LOD0"])
    groove.rotation_euler[0] = math.radians(90.0)
    groove["role"] = "control/handle_linear"

    low = add_cylinder("lod__control_handle_linear__body_lod1", (0.18, 0.0, 0.08), 0.05, 0.035, mats["control_body"], collections["LOD1"], vertices=32)
    low.rotation_euler[0] = math.radians(90.0)
    low["role"] = "control/handle_linear"
    low["lod"] = "LOD1"

    collision = add_uv_sphere("collision__control_handle_linear__sphere_0_16m", (0.0, 0.0, 0.08), 0.08, mats["collision_hidden"], collections["COLLISION"], segments=32, rings=16)
    collision.display_type = "WIRE"
    collision.hide_render = True
    collision["role"] = "control/handle_linear"
    collision["collision_proxy"] = "sphere"
    collision["diameter_m"] = 0.16

    focus_socket = add_torus("socket__control_handle_linear__focus_ring_0_14m", (0.0, 0.0, 0.08), 0.07, 0.004, mats["control_focus"], collections["SOCKETS"])
    focus_socket.rotation_euler[0] = math.radians(90.0)
    focus_socket["socket"] = "control_focus"
    focus_socket["role"] = "control/handle_linear"

    origin = add_empty("origin__control_handle_linear__center", (0.0, 0.0, 0.08), collections["SOCKETS"], display_size=0.10)
    origin["role"] = "control/handle_linear"
    origin["pivot"] = "center"

    # Camera and light are preview-only and should not be included in runtime exports.
    bpy.ops.object.light_add(type="AREA", location=(1.8, -2.4, 2.0))
    light = bpy.context.object
    light.name = "preview__area_light_do_not_export"
    light.data.energy = 450
    light.data.size = 3.0
    link_to(collections["PREVIEW"], light)

    bpy.ops.object.camera_add(location=(1.8, -2.2, 1.25), rotation=(math.radians(62), 0, math.radians(40)))
    camera = bpy.context.object
    camera.name = "preview__camera_do_not_export"
    camera.data.lens = 35
    scene.camera = camera
    link_to(collections["PREVIEW"], camera)

    semantic_materials = {
        "collision_hidden",
        "control_active",
        "control_body",
        "control_focus",
        "data_matte",
        "data_selected_outline",
        "guide_panel",
        "reference",
        "status_error",
        "status_warning",
        "structure_quiet",
    }
    for mat in list(bpy.data.materials):
        if mat.name not in semantic_materials:
            bpy.data.materials.remove(mat)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT))


if __name__ == "__main__":
    build_scene()
    print(f"Created {OUTPUT}")
