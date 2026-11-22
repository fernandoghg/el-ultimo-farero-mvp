"""Ancient stone/bronze reflector art V1. Blender 5.2.3 LTS, local sources only.
Godot pivot (0,1.2,0), mirror normal +X. Static pedestal and yawing assembly.
"""
from pathlib import Path
import bpy
import bmesh
import math
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'art_source/reflector_art_v1'
EXPORT = ROOT/'assets/reflector_art_v1'
SOURCE.mkdir(parents=True,exist_ok=True)
EXPORT.mkdir(parents=True,exist_ok=True)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)


def linear(v):
    return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4


def mat(name,rgb,roughness=.9,metallic=0):
    m=bpy.data.materials.new(name)
    m.use_nodes=True
    color=tuple(linear(v) for v in rgb)
    m.diffuse_color=(*color,1)
    bsdf=m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=(*color,1)
    bsdf.inputs['Roughness'].default_value=roughness
    bsdf.inputs['Metallic'].default_value=metallic
    bsdf.inputs['Specular IOR Level'].default_value=.25
    return m


stone=mat('Warm_aged_limestone',(.50,.48,.42))
stone_light=mat('Stone_exposed_edges',(.60,.57,.50))
stone_dark=mat('Stone_earthy_recesses',(.35,.34,.30))
bronze=mat('Aged_bronze',(.43,.31,.17),.78,.55)
bronze_edge=mat('Bronze_worn_edges',(.64,.48,.26),.7,.5)
patina=mat('Bronze_sparse_patina',(.24,.39,.34),.92,.15)
silver=mat('Soft_polished_tin',(.72,.82,.81),.4,.32)
parts={'Pedestal':[],'RotatingAssembly':[]}


def register(obj,name,material,group):
    obj.name=name
    obj.data.materials.append(material)
    parts[group].append(obj)
    return obj


def bevel(obj,width=.012):
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Soft_worn_edges','BEVEL')
    mod.width=width
    mod.segments=3
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def cylinder(name,center,radius,depth,material,group,vertices=24,axis='Z',edge=.006):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=center)
    obj=bpy.context.object
    if axis=='Y':
        obj.rotation_euler.x=math.pi/2
    elif axis=='X':
        obj.rotation_euler.y=math.pi/2
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    register(obj,name,material,group)
    return bevel(obj,edge) if edge else obj


def block(name,center,size,material,group,width=.012):
    bpy.ops.mesh.primitive_cube_add(size=1,location=center)
    obj=bpy.context.object
    obj.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    register(obj,name,material,group)
    return bevel(obj,width)


def ring(name,z,radius,tube,material,group):
    bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,
                                   major_radius=radius,minor_radius=tube,location=(0,0,z))
    obj=bpy.context.object
    register(obj,name,material,group)
    for p in obj.data.polygons:
        p.use_smooth=True
    return obj


def stone_course(name,z0,z1,r0,r1,phase):
    n=10
    vertices=[]
    for z,r in [(z0,r0),(z1,r1)]:
        for i in range(n):
            a=2*math.pi*i/n+math.pi/10
            irregular=1+.022*math.sin(i*2.1+phase)+.013*math.cos(i*.9+phase)
            vertices.append((r*irregular*math.cos(a),r*irregular*math.sin(a),z))
    faces=[tuple(reversed(range(n))),tuple(n+i for i in range(n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    register(obj,name,stone,'Pedestal')
    mesh.materials.append(stone_light)
    mesh.materials.append(stone_dark)
    for i,face in enumerate(mesh.polygons):
        face.material_index=1 if i%5==1 else 2 if i%7==4 else 0
    bevel(obj,.012)
    return obj


# Three broad courses, a weathered foot and a capital. No high-frequency masonry.
stone_course('Battered_plinth',0,.115,.286,.281,.3)
stone_course('Lower_course',.12,.25,.238,.228,1.1)
stone_course('Middle_course',.263,.393,.226,.217,2.0)
stone_course('Upper_course',.406,.536,.215,.205,3.1)
cylinder('Joint_core',(0,0,.33),.19,.43,stone_dark,'Pedestal',vertices=16,edge=0)
stone_course('Capital',.54,.635,.228,.277,1.4)
cylinder('Fixed_bearing',(0,0,.655),.242,.04,bronze,'Pedestal')
ring('Bearing_moulding',.68,.222,.009,bronze_edge,'Pedestal')
# Two discreet stationary orientation stations, one or two cuts, no numbers.
for side in [-1,1]:
    a=side*math.pi/4
    x,y=.252*math.cos(a),.252*math.sin(a)
    for offset in ([0] if side==-1 else [-.018,.018]):
        mark=block('Fixed_orientation_cut',(x-offset*math.sin(a),y+offset*math.cos(a),.641),
                   (.042,.013,.008),bronze_edge,'Pedestal',.003)
        mark.rotation_euler.z=a
# A broad stone inset/cut on the front, no minute engraving.
block('Stone_inset_recess',(.220,0,.325),(.012,.106,.055),stone_dark,'Pedestal',.006)
block('Stone_inset_bronze',(.228,0,.325),(.009,.055,.022),bronze,'Pedestal',.004)

# Rotating bearing and fork; origin will be set to the existing optical pivot.
cylinder('Rotating_table',(0,0,.716),.209,.044,bronze,'RotatingAssembly')
ring('Table_edge',.74,.188,.009,bronze_edge,'RotatingAssembly')
cylinder('Yaw_spindle',(0,0,.79),.073,.12,bronze,'RotatingAssembly',vertices=20)
block('Fork_cross_member',(-.057,0,.805),(.09,.89,.075),bronze,'RotatingAssembly',.022)
for side in [-1,1]:
    block('Fork_upright',(-.065,side*.432,1.005),(.085,.06,.424),bronze,'RotatingAssembly',.022)
    cylinder('Side_bearing',(-.04,side*.432,1.2),.067,.054,bronze_edge,'RotatingAssembly',16,'Y')
    cylinder('Side_bolt',(-.04,side*.463,1.2),.028,.012,bronze,'RotatingAssembly',6,'Y',.003)


def profile(half_width,half_height,chamfer):
    return [(-half_width+chamfer,-half_height),(half_width-chamfer,-half_height),
            (half_width,-half_height+chamfer),(half_width,half_height-chamfer),
            (half_width-chamfer,half_height),(-half_width+chamfer,half_height),
            (-half_width,half_height-chamfer),(-half_width,-half_height+chamfer)]


# Frame cross-section lies in Blender Y/Z (Godot -Z/Y); optical normal is +X.
def frame():
    outer=profile(.465,.39,.095)
    inner=profile(.403,.33,.072)
    vertices=[]
    for x in [-.053,.053]:
        for outline in [outer,inner]:
            vertices += [(x,y,1.2+z) for y,z in outline]
    faces=[]
    for i in range(8):
        j=(i+1)%8
        faces += [(i,j,16+j,16+i),(8+j,8+i,24+i,24+j),
                  (j,i,8+i,8+j),(16+i,16+j,24+j,24+i)]
    mesh=bpy.data.meshes.new('Bronze_frame')
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj=bpy.data.objects.new('Bronze_frame',mesh)
    bpy.context.collection.objects.link(obj)
    register(obj,'Octagonal_bronze_frame',bronze_edge,'RotatingAssembly')
    bevel(obj,.009)
    return obj


frame()
outline=profile(.407,.334,.072)
vertices=[(x,y,1.2+z) for x in [-.025,.025] for y,z in outline]
faces=[tuple(reversed(range(8))),tuple(8+i for i in range(8))]
faces += [(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
mesh=bpy.data.meshes.new('Reflective_inlay')
mesh.from_pydata(vertices,[],faces)
mesh.update()
obj=bpy.data.objects.new('Reflective_inlay',mesh)
bpy.context.collection.objects.link(obj)
register(obj,'Reflective_inlay',silver,'RotatingAssembly')
bevel(obj,.006)
# Sparse patina in two recesses, raised or inset geometry rather than coplanar decals.
for y,z in [(-.437,1.33),(.437,1.08)]:
    block('Patina_in_recess',(-.056,y,z),(.012,.016,.08),patina,'RotatingAssembly',.005)
for side in [-1,1]:
    for z in [.845,1.555]:
        cylinder('Frame_rivet',(side*.057,0,z),.015,.012,bronze,'RotatingAssembly',12,'X',.003)
# A rotating index on the table, aligned with normal +X, clear of the mirror.
mesh=bpy.data.meshes.new('Rotating_index')
mesh.from_pydata([(.145,-.027,.746),(.238,0,.746),(.145,.027,.746)],[],[(0,1,2)])
mesh.update()
obj=bpy.data.objects.new('Rotating_index',mesh)
bpy.context.collection.objects.link(obj)
register(obj,'Rotating_index',patina,'RotatingAssembly')

root=bpy.data.objects.new('AncientReflectorV1',None)
bpy.context.collection.objects.link(root)
objects=[]
for name,group in parts.items():
    bpy.ops.object.select_all(action='DESELECT')
    for obj in group:
        obj.select_set(True)
    bpy.context.view_layer.objects.active=group[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    bpy.context.scene.cursor.location=(0,0,0) if name=='Pedestal' else (0,0,1.2)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    obj.parent=root
    # Recalculate face winding after custom profile construction.
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.dissolve_degenerate(bm,dist=1e-7,edges=list(bm.edges))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    objects.append(obj)
bpy.context.scene.cursor.location=(0,0,0)
bpy.context.scene.unit_settings.system='METRIC'
bpy.context.scene.unit_settings.scale_length=1.0
bpy.ops.object.select_all(action='SELECT')
coords=[o.matrix_world @ v.co for o in objects for v in o.data.vertices]
low=[min(p[i] for p in coords) for i in range(3)]
high=[max(p[i] for p in coords) for i in range(3)]
triangles=0
for obj in objects:
    obj.data.calc_loop_triangles()
    triangles+=len(obj.data.loop_triangles)
    assert all(p.area>1e-12 for p in obj.data.polygons),'Degenerate geometry'
metrics={'blender':bpy.app.version_string,'triangles':triangles,'materials':7,'meshes':2,
         'dimensions_godot':[high[0]-low[0],high[2]-low[2],high[1]-low[1]],
         'bounds_godot':{'x':[low[0],high[0]],'y':[low[2],high[2]],'z':[-high[1],-low[1]]},
         'pivot_godot':[0,1.2,0],'normal_godot':[1,0,0],
         'yaw_states_degrees':[-45,45],
         'components':['Pedestal','RotatingAssembly']}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'ancient_reflector_v1.blend'))
bpy.ops.export_scene.gltf(filepath=str(EXPORT/'ancient_reflector_v1.glb'),export_format='GLB',
                         use_selection=True,export_apply=True,export_yup=True,
                         export_animations=False,export_cameras=False,export_lights=False)
(EXPORT/'model-metrics.json').write_text(json.dumps(metrics,indent=2)+'\n',encoding='utf8')
print('REFLECTOR_ART_OK',json.dumps(metrics))
