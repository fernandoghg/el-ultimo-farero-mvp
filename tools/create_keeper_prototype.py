"""Local, reproducible lighthouse keeper V1. Blender 5.2.3 LTS; no addons.
Front is Blender -Y / Godot +Z. Origin at soles; no rig, colliders or lights.
"""
from pathlib import Path
import bpy
import math
import json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art_source/keeper_prototype'
EXPORT = ROOT / 'assets/keeper_prototype'
SOURCE.mkdir(parents=True, exist_ok=True)
EXPORT.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)


def linear(c):
    return c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4


def material(name, rgb, roughness=.9, metallic=0, emission=0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    color = tuple(linear(v) for v in rgb)
    m.diffuse_color = (*color, 1)
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Specular IOR Level'].default_value = .22
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*color, 1)
        bsdf.inputs['Emission Strength'].default_value = emission
    return m


navy = material('Coat_indigo_wool', (.13,.24,.33))
edge_blue = material('Coat_worn_blue_edges', (.23,.36,.43))
skin = material('Skin_warm_peach', (.78,.56,.39))
trousers = material('Trousers_umber', (.36,.26,.19))
boot = material('Boots_oxhide', (.23,.14,.095))
sole = material('Boot_soles_dark', (.12,.09,.07))
leather = material('Belt_worn_leather', (.41,.26,.13))
brass = material('Brass_muted', (.69,.52,.26), .7, .35)
hair = material('Hair_and_eyes_charcoal', (.14,.105,.075))
linen = material('Scarf_sand_linen', (.72,.64,.46))
metal = material('Lantern_aged_iron', (.19,.22,.22), .75, .45)
light = material('Lantern_amber_lens', (1,.64,.17), .65, 0, .8)
parts = {}


def register(obj, group, mat):
    obj.data.materials.append(mat)
    parts.setdefault(group, []).append(obj)
    return obj


def smooth(obj):
    for p in obj.data.polygons:
        p.use_smooth = True


def loft(name, rings, mat, group, segments=16, power=.78, subdiv=1):
    vertices = []
    for cx,cy,z,rx,ry in rings:
        for j in range(segments):
            angle = 2*math.pi*j/segments
            c,s = math.cos(angle),math.sin(angle)
            vertices.append((cx+rx*math.copysign(abs(c)**power,c),
                             cy+ry*math.copysign(abs(s)**power,s),z))
    faces = [tuple(reversed(range(segments)))]
    for i in range(len(rings)-1):
        for j in range(segments):
            k=(j+1)%segments
            faces.append((i*segments+j,i*segments+k,(i+1)*segments+k,(i+1)*segments+j))
    faces.append(tuple((len(rings)-1)*segments+j for j in range(segments)))
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    register(obj,group,mat)
    if subdiv:
        bpy.context.view_layer.objects.active=obj
        mod=obj.modifiers.new('Soft_tailored_surface','SUBSURF')
        mod.levels=subdiv
        bpy.ops.object.modifier_apply(modifier=mod.name)
    smooth(obj)
    return obj


def oval(name, center, scale, mat, group, segments=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=center)
    obj=bpy.context.object
    obj.name=name
    obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    register(obj,group,mat)
    smooth(obj)
    return obj


def rounded_box(name, center, size, mat, group, bevel=.018):
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    obj=bpy.context.object
    obj.name=name
    obj.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    register(obj,group,mat)
    mod=obj.modifiers.new('Soft_crafted_edges','BEVEL')
    mod.width=bevel
    mod.segments=3
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def cord(name, points, radius, mat, group, resolution=2):
    curve=bpy.data.curves.new(name,'CURVE')
    curve.dimensions='3D'
    curve.resolution_u=8
    curve.bevel_depth=radius
    curve.bevel_resolution=resolution
    curve.use_fill_caps=True
    spline=curve.splines.new('BEZIER')
    spline.bezier_points.add(len(points)-1)
    for bp,point in zip(spline.bezier_points,points):
        bp.co=point
        bp.handle_left_type='AUTO'
        bp.handle_right_type='AUTO'
    obj=bpy.data.objects.new(name,curve)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    register(obj,group,mat)
    smooth(obj)
    obj.select_set(False)
    return obj


# Flared short coat: sculpted ring profiles, no primitive torso cylinder.
loft('Coat_tailored_shell',[(0,0,.54,.245,.15),(0,0,.56,.25,.155),
     (0,.006,.72,.23,.15),(0,.005,.84,.205,.135),(0,.008,1.02,.235,.145),
     (0,.012,1.105,.23,.13),(0,.005,1.16,.145,.105)],navy,'Torso')
# Hem piping and back yoke make the rear view readable.
loft('Coat_hem_band',[(0,0,.555,.249,.158),(0,0,.58,.249,.158)],edge_blue,'Torso',subdiv=0)
cord('Back_yoke',[(-.19,.118,1.06),(0,.15,1.035),(.19,.118,1.06)],.009,edge_blue,'Torso')
cord('Back_split_seam',[(0,.151,.58),(0,.158,.69),(0,.143,.79)],.005,edge_blue,'Torso',1)
# Collar and scarf form a light break below the head.
loft('Standing_collar',[(0,0,1.095,.145,.111),(0,0,1.13,.16,.12),(0,0,1.19,.115,.095)],edge_blue,'Torso',subdiv=0)
loft('Scarf_wrap',[(0,-.005,1.13,.115,.105),(0,-.005,1.17,.127,.109),(0,-.005,1.195,.1,.09)],linen,'Torso',subdiv=0)
scarf=rounded_box('Scarf_short_end',(-.075,-.153,1.035),(.075,.025,.19),linen,'Torso',.012)
scarf.rotation_euler.y=-.12
cord('Front_placket',[(.018,-.151,.69),(.018,-.148,.85),(.018,-.151,1.08)],.012,edge_blue,'Torso')
for z in [.79,.9,1.01]:
    oval('Coat_button',(0.023,-.166,z),(.015,.009,.015),brass,'Torso',12,8)
# Two welt pockets, not distracting high-frequency stitching.
for sign in [-1,1]:
    cord('Pocket_welt',[(sign*.105,-.153,.72),(sign*.195,-.128,.75)],.012,edge_blue,'Torso')
loft('Leather_belt',[(0,0,.803,.217,.149),(0,0,.852,.217,.149)],leather,'Torso',subdiv=0)
rounded_box('Belt_buckle',(0,-.161,.827),(.065,.026,.047),brass,'Torso',.007)
rounded_box('Buckle_inset',(0,-.177,.827),(.038,.009,.024),boot,'Torso',.003)

# Legs and broad rounded footwear, separated for future pivots.
for sign,side in [(-1,'L'),(1,'R')]:
    x=sign*.12
    loft('Trouser_'+side,[(x,0,.17,.086,.081),(x,0,.2,.087,.087),
         (x,.008,.35,.087,.09),(sign*.108,.006,.55,.105,.103),
         (sign*.105,.006,.62,.101,.1)],trousers,'Leg_'+side)
    loft('Boot_upper_'+side,[(x,.006,.08,.096,.105),(x,.008,.16,.1,.105),
         (x,.008,.28,.096,.095),(x,.008,.295,.097,.095)],boot,'Leg_'+side)
    loft('Boot_cuff_'+side,[(x,.008,.265,.101,.099),(x,.008,.295,.101,.099)],leather,'Leg_'+side,subdiv=0)
    rounded_box('Boot_sole_'+side,(x,-.06,.032),(.195,.32,.064),sole,'Leg_'+side,.026)
    oval('Boot_toe_'+side,(x,-.085,.093),(.101,.171,.088),boot,'Leg_'+side)

# Slightly bowed resting arms. Hands have palms, curled fingers and a thumb.
for sign,side in [(-1,'L'),(1,'R')]:
    loft('Sleeve_'+side,[(sign*.335,-.008,.73,.07,.072),
         (sign*.34,-.002,.78,.075,.077),(sign*.33,.01,.89,.078,.083),
         (sign*.288,.01,1.035,.09,.094),(sign*.245,.01,1.105,.085,.09)],navy,'Arm_'+side)
    loft('Cuff_'+side,[(sign*.337,-.008,.725,.073,.075),
         (sign*.338,-.008,.765,.076,.078)],edge_blue,'Arm_'+side,subdiv=0)
    oval('Palm_'+side,(sign*.34,-.015,.689),(.065,.055,.074),skin,'Arm_'+side)
    oval('Thumb_'+side,(sign*.294,-.052,.699),(.032,.039,.047),skin,'Arm_'+side,12,8)
    for k in range(3):
        oval('Curled_finger_'+side,(sign*(.318+k*.022),-.052,.658),(.014,.018,.03),skin,'Arm_'+side,10,6)

# Head, cheeks, simple face and dark hair under a maritime cap.
oval('Neck',(0,0,1.193),(.078,.074,.095),skin,'Head')
oval('Hair_back',(0,.042,1.371),(.218,.167,.192),hair,'Head')
loft('Head_soft_cheeks',[(0,-.009,1.18,.10,.10),(0,-.018,1.205,.154,.139),
     (0,-.009,1.29,.207,.176),(0,0,1.40,.218,.18),
     (0,.005,1.49,.185,.15),(0,.005,1.52,.125,.1)],skin,'Head',segments=20)
for sign in [-1,1]:
    oval('Ear',(sign*.208,.005,1.36),(.038,.035,.063),skin,'Head',12,8)
    oval('Eye',(sign*.078,-.174,1.371),(.015,.012,.018),hair,'Head',12,8)
    cord('Brow',[(sign*.042,-.176,1.405),(sign*.078,-.18,1.416),(sign*.111,-.165,1.405)],.01,hair,'Head',1)
oval('Nose',(0,-.194,1.335),(.043,.053,.044),skin,'Head')
cord('Mouth',[(-.034,-.173,1.273),(0,-.181,1.266),(.034,-.173,1.273)],.006,hair,'Head',1)
for sign in [-1,1]:
    oval('Moustache',(sign*.03,-.187,1.297),(.039,.015,.016),hair,'Head',12,8)
# Crown is domed with a distinct band and a small curved peak.
loft('Cap_crown',[(0,.012,1.475,.219,.18),(0,.015,1.50,.237,.194),
     (0,.025,1.555,.231,.185),(0,.025,1.604,.178,.143),
     (0,.025,1.619,.085,.07)],navy,'Head',segments=24,power=1)
loft('Cap_band',[(0,.008,1.47,.222,.182),(0,.008,1.505,.226,.186)],edge_blue,'Head',segments=24,power=1,subdiv=0)
oval('Cap_peak',(0,-.151,1.482),(.222,.125,.018),navy,'Head',24,8)
oval('Cap_badge',(0,-.188,1.528),(.027,.009,.025),brass,'Head',12,8)
cord('Cap_rope',[(-.15,-.145,1.493),(0,-.197,1.493),(.15,-.145,1.493)],.008,brass,'Head',1)

# Small handmade lantern, fixed prop. Emissive lens, never an added light.
lx,ly=.365,-.055
rounded_box('Lantern_lens',(lx,ly,.467),(.126,.118,.165),light,'Lantern',.015)
for z in [.365,.562]:
    rounded_box('Lantern_rim',(lx,ly,z),(.174,.16,.035),metal,'Lantern',.012)
for sx in [-1,1]:
    for sy in [-1,1]:
        cord('Lantern_frame',[(lx+sx*.071,ly+sy*.065,.382),
             (lx+sx*.068,ly+sy*.061,.55)],.009,metal,'Lantern',1)
loft('Lantern_cap',[(lx,ly,.566,.08,.073),(lx,ly,.594,.054,.05),
     (lx,ly,.608,.032,.03)],metal,'Lantern',segments=12,power=.7,subdiv=0)
cord('Lantern_handle',[(lx-.056,ly,.586),(lx-.061,ly,.653),
     (lx,ly,.693),(lx+.061,ly,.653),(lx+.056,ly,.586)],.01,metal,'Lantern')

# Join only rigid anatomical/prop groups; pivots are ready for later simple posing.
pivots={'Torso':(0,0,.84),'Head':(0,0,1.19),'Arm_L':(-.245,.01,1.09),
        'Arm_R':(.245,.01,1.09),'Leg_L':(-.11,0,.56),
        'Leg_R':(.11,0,.56),'Lantern':(lx,ly,.687)}
root=bpy.data.objects.new('KeeperPrototypeV1',None)
bpy.context.collection.objects.link(root)
meshes=[]
for group,objects in parts.items():
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=group
    bpy.context.scene.cursor.location=pivots[group]
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    obj.parent=root
    meshes.append(obj)
bpy.context.scene.cursor.location=(0,0,0)
bpy.context.scene.unit_settings.system='METRIC'
bpy.context.scene.unit_settings.scale_length=1
bpy.ops.object.select_all(action='SELECT')
coords=[obj.matrix_world @ v.co for obj in meshes for v in obj.data.vertices]
low=[min(v[i] for v in coords) for i in range(3)]
high=[max(v[i] for v in coords) for i in range(3)]
triangles=0
used=set()
for obj in meshes:
    obj.data.calc_loop_triangles()
    triangles+=len(obj.data.loop_triangles)
    for mat in obj.data.materials:
        used.add(mat.name)
    assert all(face.area>1e-12 for face in obj.data.polygons),'Degenerate face: '+obj.name
metrics={'blender':bpy.app.version_string,'triangles':triangles,'mesh_objects':len(meshes),
         'materials':sorted(used),'material_count':len(used),
         'bounds_godot':{'x':[low[0],high[0]],'y':[low[2],high[2]],'z':[-high[1],-low[1]]},
         'dimensions_godot':[high[0]-low[0],high[2]-low[2],high[1]-low[1]],
         'front_godot':'+Z','rig':False,'animations':0,'pivots_blender':pivots}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'keeper_v1.blend'))
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'keeper_v1.glb'),export_format='GLB',
                         use_selection=True,export_apply=True,export_yup=True,
                         export_animations=False,export_cameras=False,export_lights=False)
(EXPORT/'model-metrics.json').write_text(json.dumps(metrics,indent=2)+'\n',encoding='utf8')
print('KEEPER_V1_OK',json.dumps(metrics))
