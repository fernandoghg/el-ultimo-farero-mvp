"""Export an already-open lighthouse .blend without changing its source file."""
from pathlib import Path
import bpy
import sys

root = Path(__file__).resolve().parents[1]
target = root / "assets" / "lighthouse" / "lighthouse.glb"
if "--" in sys.argv:
    target = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
bpy.ops.object.select_all(action="DESELECT")
for name in ("TowerArt", "LensArt"):
    obj = bpy.data.objects.get(name)
    if obj is None or obj.type != "MESH":
        raise RuntimeError("Expected authoring mesh: " + name)
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB",
                          use_selection=True, export_yup=True,
                          export_animations=False, export_cameras=False,
                          export_lights=False, export_apply=True)
print("LIGHTHOUSE_EXPORT_OK", bpy.app.version_string, target)
