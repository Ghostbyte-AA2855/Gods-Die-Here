"""Light and render the Godot arena meshes in Blender background mode."""

import argparse
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

VIEW_DIRECTION = Vector((1.12, 4.4, 0.56)).normalized()


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


def ground_surface(bottom):
    bpy.ops.mesh.primitive_plane_add(size=200.0, location=(0, 0, bottom - 0.009))
    arena_floor = bpy.context.object
    material = bpy.data.materials.new("Worn charcoal slate")
    material.use_nodes = True
    tree = material.node_tree
    shader = tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = 0.85
    shader.inputs["Specular IOR Level"].default_value = 0.24
    texture = tree.nodes.new("ShaderNodeTexNoise")
    texture.inputs["Scale"].default_value = 13.0
    texture.inputs["Detail"].default_value = 3.0
    coords = tree.nodes.new("ShaderNodeTexCoord")
    tree.links.new(coords.outputs["Object"], texture.inputs["Vector"])
    slate = tree.nodes.new("ShaderNodeValToRGB")
    slate.color_ramp.elements[0].position = 0.19
    slate.color_ramp.elements[0].color = (0.013, 0.011, 0.012, 1)
    slate.color_ramp.elements[1].position = 0.82
    slate.color_ramp.elements[1].color = (0.031, 0.029, 0.029, 1)
    tree.links.new(texture.outputs["Fac"], slate.inputs["Fac"])
    tree.links.new(slate.outputs["Color"], shader.inputs["Base Color"])
    bump = tree.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.26
    bump.inputs["Distance"].default_value = 0.012
    tree.links.new(texture.outputs["Fac"], bump.inputs["Height"])
    tree.links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    arena_floor.data.materials.append(material)


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
    camera.data.ortho_scale = max(2.45, (xmax - xmin) * 1.13, (ymax - ymin) * 1.13)
    scene.camera = camera

    ground_surface(bottom)
    scene.world = bpy.data.worlds.new("Unlit arena air")
    scene.world.use_nodes = True
    ambient = scene.world.node_tree.nodes.get("Background")
    ambient.inputs["Color"].default_value = (0.56, 0.65, 0.78, 1)
    ambient.inputs["Strength"].default_value = 0.055
    light("High limestone key", (-2.1, 2.35, 4.4), center, 490.0, 1.45, (1.0, 0.91, 0.80))
    light("Muted front bounce", (2.8, 3.65, 1.9), center, 110.0, 2.4, (0.67, 0.78, 1.0))
    light("Dusk rim", (2.0, -1.7, 3.0), center, 465.0, 1.35, (0.61, 0.75, 1.0))
    light("Coal rim", (-1.8, -2.3, 1.8), center, 280.0, 1.5, (1.0, 0.47, 0.24))

    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = False
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
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
