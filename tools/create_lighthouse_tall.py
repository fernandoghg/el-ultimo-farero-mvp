"""Independent tall artwork. Never overwrites or executes the compact source. Run with Blender --background --factory-startup --python this_file.

Writes a .blend authoring source outside Godot's import tree and a two-mesh GLB.
No add-ons, textures, downloads, cameras, lights or physics are exported.
"""
from pathlib import Path
import math
import bpy

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art_source" / "lighthouse_tall"
EXPORT = ROOT / "assets" / "lighthouse_tall"
SOURCE.mkdir(parents=True, exist_ok=True)
EXPORT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
parts = []
lens_parts = []


def material(name, color, roughness=0.85, metal=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metal
    return mat


stone = [material("Limestone_%d" % i, c) for i, c in enumerate([
    (0.38, 0.36, 0.29), (0.43, 0.40, 0.32),
    (0.34, 0.33, 0.28), (0.40, 0.39, 0.33)])]
mortar = material("Recessed_lime_joints", (0.16, 0.17, 0.15))
metal = material("Weathered_dark_bronze", (0.075, 0.09, 0.095), 0.57, 0.65)
trim = material("Muted_brass", (0.29, 0.22, 0.105), 0.55, 0.6)
door = material("Recessed_service_panel", (0.105, 0.12, 0.11), 0.9)
amber = material("Beacon_idle_amber", (0.27, 0.16, 0.055), 0.3)


def finish(obj, mat, bevel=0.0, group=None):
    obj.data.materials.append(mat)
    bpy.context.view_layer.objects.active = obj
    if bevel:
        mod = obj.modifiers.new("Soft_hand_worn_edges", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
        normal = obj.modifiers.new("Weighted_corner_normals", "WEIGHTED_NORMAL")
        normal.keep_sharp = True
        bpy.ops.object.modifier_apply(modifier=normal.name)
    (parts if group is None else group).append(obj)
    return obj


def box(name, location, size, mat, bevel=0.01, rotation=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_euler.z = rotation
    return finish(obj, mat, bevel)


def tapered(name, z0, z1, half0, half1, mat, bevel=0.01):
    vertices = [(x * h, y * h, z) for h, z in [(half0, z0), (half1, z1)]
                for x, y in [(-1, -1), (1, -1), (1, 1), (-1, 1)]]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
             (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj, mat, bevel)


# A closed recessed core gives the joints real depth, without holes in the tower.
tapered("Mortar_core", 0.015, 3.14, 0.515, 0.425, mortar, 0.018)
# Broad foundation blocks: slight asymmetry and bevels imply erosion, not new steps.
for side in range(4):
    angle = side * math.pi / 2
    for j in range(2):
        u = (-0.265 if j == 0 else 0.265)
        x, y = u, -0.48
        box("Eroded_foundation", (x*math.cos(angle)-y*math.sin(angle),
                                  x*math.sin(angle)+y*math.cos(angle), 0.125),
            (0.522, 0.14, 0.24), stone[(side+j) % 4], 0.024, angle)

# Twelve courses with staggered vertical joints and restrained per-block variation.
for course in range(12):
    z = 0.25 + course * 0.235 + 0.112
    half = 0.54 - (z / 3.14) * 0.095
    cuts = [-half, -0.09, half] if course % 2 else [-half, 0.09, half]
    for side in range(4):
        angle = side * math.pi / 2
        for j in range(2):
            u = (cuts[j] + cuts[j+1]) / 2
            x, y = u, -(half - 0.065)
            box("Course_%02d_block_%d_%d" % (course, side, j),
                (x*math.cos(angle)-y*math.sin(angle),
                 x*math.sin(angle)+y*math.cos(angle), z),
                (cuts[j+1]-cuts[j]-0.01, 0.13, 0.224),
                stone[(course*3+side+j) % 4], 0.012, angle)

# Flat service panel, within the existing collision footprint; no implied entrance.
box("Service_panel", (0, -0.515, 0.70), (0.29, 0.014, 0.62), door, 0.018)
box("Panel_brass_latch", (0.075, -0.526, 0.70), (0.025, 0.009, 0.045), trim, 0.004)
box("Stone_lintel", (0, -0.475, 1.05), (0.40, 0.075, 0.10), stone[1], 0.012)
tapered("Upper_stone_coping", 3.10, 3.20, 0.46, 0.54, stone[1], 0.012)
box("Bronze_lantern_sill", (0, 0, 3.235), (1.12, 1.12, 0.07), metal, 0.014)
box("Sill_brass_inlay", (0, 0, 3.283), (1.04, 1.04, 0.025), trim, 0.006)
for x in [-0.475, 0.475]:
    for y in [-0.475, 0.475]:
        box("Lantern_corner_post", (x, y, 3.505), (0.065, 0.065, 0.43), metal, 0.008)
box("Upper_lantern_band", (0, 0, 3.735), (1.10, 1.10, 0.045), metal, 0.009)
tapered("Low_hipped_metal_roof", 3.7575, 3.90, 0.57, 0.30, metal, 0.008)

# A continuous faceted lens with concentric Fresnel steps. One material slot allows
# the unchanged Godot Beacon script to replace it with the activated warm material.
for i, radius in enumerate([0.28, 0.33, 0.36, 0.33, 0.28]):
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=radius, depth=0.065,
                                      location=(0, 0, 3.35 + i * 0.067))
    obj = bpy.context.object
    obj.name = "Fresnel_lens_%d" % i
    finish(obj, amber, 0.004, lens_parts)


glass = material("Smoked_glass_facets", (0.14, 0.22, 0.24), 0.25)
for side in range(4):
    angle = side * math.pi / 2
    for x in [-0.36, 0.36]:
        y = -0.465
        box("Inset_glass_panel", (x*math.cos(angle)-y*math.sin(angle),
                                 x*math.sin(angle)+y*math.cos(angle), 3.505),
            (0.15, 0.012, 0.33), glass, 0.005, angle)


def join(group, name, origin_z):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in group:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = group[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.context.scene.cursor.location = (0, 0, origin_z)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    # Material indices are retained. Geometry is static, with applied modifiers.
    return obj


tower = join(parts, "TowerArt", 1.0)
lens = join(lens_parts, "LensArt", 2.2)
bpy.context.scene.unit_settings.system = "METRIC"
bpy.context.scene.unit_settings.scale_length = 1.0
for obj in [tower, lens]:
    for mat in obj.data.materials:
        mat.use_backface_culling = True
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "lighthouse.blend"))
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=str(EXPORT / "lighthouse.glb"),
                          export_format="GLB", use_selection=True,
                          export_yup=True, export_animations=False,
                          export_cameras=False, export_lights=False,
                          export_apply=True)
triangles = sum(len(p.vertices)-2 for o in [tower, lens] for p in o.data.polygons)
print("LIGHTHOUSE_TALL_ART_OK", bpy.app.version_string, "triangles", triangles,
      "source", SOURCE / "lighthouse.blend", "glb", EXPORT / "lighthouse.glb")
