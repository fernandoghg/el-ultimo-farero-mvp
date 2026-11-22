"""Re-export the approved island meshes from their Blender sources."""
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "island_v32"
EXPORTS = (
    ("island.blend", "island.glb", (
        "Cliff", "CliffDebris", "GrassCap", "LandingCap", "Meadow", "Masonry",
        "FlagstoneFragments", "WindShapedTrunk", "WindShapedTrunk.001", "WindShapedTrunk.002",
    )),
    ("landing_cliff.blend", "landing_cliff.glb", ("LandingCliff",)),
)

for source, output, names in EXPORTS:
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / "art_source" / "island_v32" / source))
    scene_objects = bpy.context.scene.objects
    missing = set(names).difference(scene_objects.keys())
    if missing:
        raise ValueError(f"{source}: missing objects {sorted(missing)}")
    for obj in scene_objects:
        obj.select_set(obj.name in names)
    bpy.ops.export_scene.gltf(
        filepath=str(ASSETS / output), export_format="GLB", use_selection=True,
        export_animations=False, export_cameras=False, export_lights=False,
    )
