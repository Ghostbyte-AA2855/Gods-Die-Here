"""Light and render the Godot arena meshes in Blender background mode."""

import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

VIEW_DIRECTION = Vector((0.72, 4.4, 1.25)).normalized()


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("--samples", type=int, default=40)
    parser.add_argument("--size", type=int, default=440)
    parser.add_argument("--only", nargs="+")
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1:])


def point_at(obj, target):
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def light(label, location, target, power, diameter, color):
    bpy.ops.object.light_add(type="AREA", location=location)
    lamp = bpy.context.object
    lamp.name = label
    lamp.data.energy = power
    lamp.data.shape = "DISK"
    lamp.data.size = diameter
    lamp.data.color = color
    point_at(lamp, target)


def frame_bounds(mesh_objects, camera):
    matrix = camera.matrix_world.inverted()
    corners = [matrix @ (obj.matrix_world @ Vector(corner))
               for obj in mesh_objects for corner in obj.bound_box]
    xmin, xmax = min(v.x for v in corners), max(v.x for v in corners)
    ymin, ymax = min(v.y for v in corners), max(v.y for v in corners)
    return xmin, xmax, ymin, ymax


def render(args, class_id):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    bpy.ops.import_scene.gltf(filepath=str(args.directory / (class_id + ".glb")))
    meshes = [obj for obj in scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"{class_id} imported with no rendered mesh geometry")

    all_corners = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    bottom = min(point.z for point in all_corners)
    top = max(point.z for point in all_corners)
    center = Vector((0.0, 0.0, (top + bottom) * 0.5))

    bpy.ops.object.camera_add(location=center + VIEW_DIRECTION * 7.5)
    camera = bpy.context.object
    point_at(camera, center)
    camera.data.type = "ORTHO"
    bpy.context.view_layer.update()
    xmin, xmax, ymin, ymax = frame_bounds(meshes, camera)
    shift = camera.matrix_world.to_3x3() @ Vector(((xmin + xmax) * 0.5, (ymin + ymax) * 0.5, 0))
    camera.location += shift
    camera.data.ortho_scale = max(2.86, (xmax - xmin) * 1.15, (ymax - ymin) * 1.19)
    scene.camera = camera

    bpy.ops.mesh.primitive_plane_add(size=200.0, location=(0, 0, bottom - 0.014))
    ground = bpy.context.object
    material = bpy.data.materials.new("Neutral obsidian floor")
    material.diffuse_color = (0.026, 0.021, 0.033, 1.0)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = material.diffuse_color
    shader.inputs["Roughness"].default_value = 0.72
    ground.data.materials.append(material)

    scene.world = bpy.data.worlds.new("Low ambient")
    scene.world.use_nodes = True
    ambient = scene.world.node_tree.nodes.get("Background")
    ambient.inputs["Color"].default_value = (0.28, 0.22, 0.35, 1)
    ambient.inputs["Strength"].default_value = 0.32
    light("Warm key", (2.5, 3.6, 4.7), center, 590.0, 3.5, (1.0, 0.83, 0.65))
    light("Cool fill", (-2.8, 2.0, 2.5), center, 320.0, 2.8, (0.62, 0.72, 1.0))
    light("Silver rim", (0.5, -2.2, 3.8), center, 540.0, 2.5, (0.8, 0.71, 1.0))

    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = False
    scene.view_settings.view_transform = "AgX"
    scene.render.resolution_x = args.size
    scene.render.resolution_y = args.size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(args.directory / (class_id + ".png"))
    bpy.ops.render.render(write_still=True)


def main():
    args = parse_arguments()
    args.directory = args.directory.resolve()
    roster = json.loads((args.directory / "champions.json").read_text())
    for champion in roster:
        if args.only is None or champion["id"] in args.only:
            render(args, champion["id"])


if __name__ == "__main__":
    main()
