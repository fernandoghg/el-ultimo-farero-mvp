"""Independent terrain V2: broad asymmetric escarpments visible from above.
Preserves V1. No production scene, physics, camera or lighting modifications.
"""
from pathlib import Path
import bpy
import bmesh
import math
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art_source/island_terrain_v2'
EXPORT = ROOT / 'assets/island_terrain_v2'
SOURCE.mkdir(parents=True, exist_ok=True)
EXPORT.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)


def linear(v):
    return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4


def material(name, hex_color):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = tuple(linear(int(hex_color[i:i+2], 16) / 255) for i in (0, 2, 4))
    m.diffuse_color = (*rgb, 1)
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*rgb, 1)
    bsdf.inputs['Roughness'].default_value = .95
    bsdf.inputs['Specular IOR Level'].default_value = .15
    m.use_backface_culling = True
    return m


materials = [material('V2_plateau_slate', '69776C'),
              material('V2_weathered_edge', '8B8B7C'),
              material('V2_exposed_schist', '687783'),
              material('V2_deep_stone', '475369')]
verts, faces, slots = [], [], []


def vertex(x, z, y):
    verts.append((x, -z, y))
    return len(verts) - 1


def face(indices, mat):
    faces.append(indices)
    slots.append(mat)


def bump(t, center, width):
    d = math.atan2(math.sin(t-center), math.cos(t-center))
    return math.exp(-(d/width)**2)


def headland(t, corner):
    e = (.30 + 1.45*bump(t, -2.90, .38) + 1.8*bump(t, -1.45, .30)
         + 2.0*bump(t, .20, .32) + 1.7*bump(t, 1.40, .35)
         + 1.3*bump(t, 2.55, .30) - .32*bump(t, .75, .16)
         - .28*bump(t, 2.0, .20))
    # Retain support at reachable corners, but avoid enormous diagonal aprons.
    return max(.10, min(2.25, e)) * (.22 + .78*(1-corner)**1.3)


N, H = 24, 5.82
# All of this cap remains at Y=0 and supported by the unchanged floor.
# An irregular geological material boundary avoids a rectangular green lid.
coords = ([(-H+2*H*i/N, -H) for i in range(N)] +
          [(H, -H+2*H*i/N) for i in range(N)] +
          [(H-2*H*i/N, H) for i in range(N)] +
          [(-H, H-2*H*i/N) for i in range(N)])
boundary = [vertex(x, z, 0) for x, z in coords]
inner = []
for x, z in coords:
    t = math.atan2(z, x)
    corner = max(abs(x/H)+abs(z/H)-1, 0)
    scale = (.82+.055*math.sin(2*t+.4)+.025*math.cos(5*t-.2))*(1-.12*corner)
    inner.append(vertex(x*scale, z*scale, 0))
center = vertex(0, 0, 0)
for i in range(len(boundary)):
    j = (i+1) % len(boundary)
    face([center, inner[j], inner[i]], 0)
    face([inner[i], inner[j], boundary[j], boundary[i]], 2)
previous = boundary
for level in range(5):
    ring = []
    for i, (x, z) in enumerate(coords):
        t = math.atan2(z, x)
        length = math.hypot(x, z)
        nx, nz = x/length, z/length
        corner = max(abs(x/H)+abs(z/H)-1, 0)
        e = headland(t, corner)
        w = .65*math.sin(2*t+.6) + .35*math.cos(5*t-.7)
        if level == 0:
            expansion, y, scale = .11, -.16, 1.0
        elif level == 1:
            expansion, y, scale = .13 + .36*e, -.53-.45*e+.08*w, 1.0
        elif level == 2:
            expansion, y, scale = .13 + e, -.92-1.05*e+.18*w, 1.0
        elif level == 3:
            expansion, y, scale = .10 + 1.03*e, -1.68-1.05*e+.25*w, 1.0
        else:
            expansion, y, scale = .30*e, -4.55+.12*w, .61
        shear = 0 if level == 0 else .10*math.sin(3*t+.2)*min(level, 2)
        px = x*scale + nx*expansion - nz*shear
        pz = z*scale + nz*expansion + nx*shear
        if level == 4:
            px -= .52
            pz += .25
        # Keep the bridge corridor open through the entire rock volume.
        if x > 5 and -4.5 < pz < -1.5:
            px = min(px, 5.93)
            if level == 0:
                px, y = 6.0, 0.0
        ring.append(vertex(px, pz, y))
    for i in range(len(ring)):
        j = (i+1) % len(ring)
        t = math.atan2(coords[i][1], coords[i][0])
        # Mineral exposures form broad interrupted patches, not repeated stripes.
        slot = 2
        if level == 1 and (bump(t, 1.1, .65) + bump(t, -2.3, .5)) > .3:
            slot = 1
        if level >= 3:
            slot = 3 if level == 4 or math.sin(2*t+.4) < -.25 else 2
        face([previous[i], previous[j], ring[j], ring[i]], slot)
    previous = ring
bottom = vertex(-.85, .35, -5.05)
for i in range(len(previous)):
    face([previous[i], previous[(i+1)%len(previous)], bottom], 3)

mesh = bpy.data.meshes.new('V2_continuous_escarpment')
mesh.from_pydata(verts, [], faces)
mesh.update()
for m in materials:
    mesh.materials.append(m)
for p, slot in zip(mesh.polygons, slots):
    p.material_index = slot
bm = bmesh.new()
bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
assert all(e.is_manifold for e in bm.edges), 'Open source shell'
bm.to_mesh(mesh)
bm.free()
obj = bpy.data.objects.new('IslandTerrainV2', mesh)
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bevel = obj.modifiers.new('Broad_weathering', 'BEVEL')
bevel.width = .035
bevel.segments = 2
bevel.limit_method = 'ANGLE'
bevel.angle_limit = .55
bevel.use_clamp_overlap = True
bpy.ops.object.modifier_apply(modifier=bevel.name)
mesh = obj.data
for v in mesh.vertices:
    v.co.z = min(v.co.z, 0.0)
mesh.update()
colors = mesh.color_attributes.new(name='BroadStoneVariation', type='FLOAT_COLOR', domain='CORNER')
for loop in mesh.loops:
    p = mesh.vertices[loop.vertex_index].co
    factor = .92+.045*math.sin(p.x*.38+.3)+.03*math.cos(p.y*.51)
    colors.data[loop.index].color = (factor, factor, factor, 1)
mesh.color_attributes.active_color = colors
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1.0
mesh.calc_loop_triangles()
bm = bmesh.new()
bm.from_mesh(mesh)
nonmanifold = sum(not e.is_manifold for e in bm.edges)
bm.free()
assert nonmanifold == 0, 'Bevel opened shell'
assert all(p.area > 1e-10 for p in mesh.polygons), 'Degenerate face'
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'island_v2.blend'))
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'island_v2.glb'), export_format='GLB',
                         use_selection=True, export_apply=True, export_yup=True,
                         export_vertex_color='ACTIVE', export_animations=False,
                         export_cameras=False, export_lights=False)
metrics = {'triangles': len(mesh.loop_triangles), 'vertices': len(mesh.vertices),
           'materials': len(materials), 'non_manifold_edges': nonmanifold,
           'bounds_godot': {'x': [min(v.co.x for v in mesh.vertices), max(v.co.x for v in mesh.vertices)],
                            'y': [min(v.co.z for v in mesh.vertices), max(v.co.z for v in mesh.vertices)],
                            'z': [min(-v.co.y for v in mesh.vertices), max(-v.co.y for v in mesh.vertices)]},
           'flat_playable_half_extent': H,
           'source': 'art_source/island_terrain_v2/island_v2.blend',
           'geometry': 'Single closed shell; exterior headlands are descending rock faces, never extra floor.'}
(EXPORT/'model-metrics.json').write_text(json.dumps(metrics, indent=2)+'\n', encoding='utf8')
print('ISLAND_V2_OK', json.dumps(metrics))
