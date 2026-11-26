"""Verify and package the full animated exports produced by Godot."""

import argparse
import json
import struct
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

CORE_CLIPS = {
    "RESET", "idle", "run", "strafe_left", "strafe_right", "backpedal",
    "hit", "stagger", "rally", "dodge", "death", "channel",
}
README = """# Gods Die Here animated champion assets

Each GLB contains one champion’s 3D meshes, PBR materials and articulated joint hierarchy. Import it into a glTF 2.0 viewer or editor, then select a named animation action.

Each champion includes eight casting actions plus movement, reactions, channeling, defeat and a neutral reset pose. The champions.json manifest maps each casting action to its in-game ability. Armor and equipment follow the same joints used in the arena.

The Godot project combines these motions with rules, spell effects, audio, blood and camera movement.
"""


def glb_scene(path):
    with path.open("rb") as stream:
        header = stream.read(12)
        if len(header) != 12:
            raise ValueError(f"{path.name} has an incomplete GLB header")
        magic, version, size = struct.unpack("<III", header)
        if (magic, version) != (0x46546C67, 2) or size != path.stat().st_size:
            raise ValueError(f"{path.name} is not a complete glTF 2.0 binary")
        length, chunk = struct.unpack("<II", stream.read(8))
        if chunk != 0x4E4F534A or length > size - 20:
            raise ValueError(f"{path.name} is missing its glTF JSON chunk")
        return json.loads(stream.read(length))


def validate_champion(hero, path):
    scene = glb_scene(path)
    names = {row["action"] for row in hero["casts"]}
    if names != {f"cast_{index}" for index in range(1, 9)}:
        raise ValueError(f"{path.name} has an incomplete cast catalog")
    clips = scene.get("animations", [])
    if {clip.get("name") for clip in clips} != CORE_CLIPS | names or len(clips) != 20:
        raise ValueError(f"{path.name} has an incomplete or duplicate animation action")
    mesh_nodes = {index for index, node in enumerate(scene["nodes"]) if "mesh" in node}
    if len(mesh_nodes) < 12:
        raise ValueError(f"{path.name} has incomplete articulated geometry")
    reference_track_set = None
    for clip in clips:
        tracks = {(channel["target"]["node"], channel["target"]["path"]) for channel in clip["channels"]}
        if len(tracks) < 18 or any(node in mesh_nodes for node, _ in tracks):
            raise ValueError(f"{path.name} / {clip['name']} has incomplete joint coverage")
        if reference_track_set is None:
            reference_track_set = tracks
        elif reference_track_set != tracks:
            raise ValueError(f"{path.name} / {clip['name']} uses mismatched joints")
    animated_joints = {node for node, _ in reference_track_set}
    mesh_parents = {
        index for index, node in enumerate(scene["nodes"])
        if any(child in mesh_nodes for child in node.get("children", []))
    }
    if not mesh_parents or not mesh_parents <= animated_joints:
        raise ValueError(f"{path.name} contains geometry outside the champion joints")


def add(archive, name, data):
    entry = ZipInfo("gods-die-here-animated-champions/" + name)
    entry.compress_type = ZIP_DEFLATED
    entry.external_attr = 0o100644 << 16
    archive.writestr(entry, data, compresslevel=6)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    manifest = (args.directory / "champions.json").read_bytes()
    roster = json.loads(manifest)
    if len(roster) != 16 or len({hero["id"] for hero in roster}) != 16:
        raise ValueError("The roster must contain 16 distinct champions")
    assets = []
    for hero in roster:
        path = args.directory / (hero["id"] + ".glb")
        validate_champion(hero, path)
        assets.append(path)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(".tmp")
    with ZipFile(temporary, "w") as archive:
        add(archive, "README.md", README.encode("utf-8"))
        add(archive, "champions.json", manifest)
        for file in assets:
            add(archive, file.name, file.read_bytes())
    with ZipFile(temporary) as archive:
        if archive.testzip() is not None:
            raise ValueError("The export archive failed its CRC check")
    temporary.replace(args.output)
    print(f"Verified {len(assets)} animated GLBs with 20 actions each and archive CRC.")


if __name__ == "__main__":
    main()
