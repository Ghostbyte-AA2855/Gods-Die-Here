#!/usr/bin/env python3
"""Build a single-threaded phone-browser export of the Godot project."""

import argparse
import json
import shutil
import subprocess
import tempfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


PROJECT_ROOT = Path(__file__).resolve().parents[2]
MOBILE_TOOLS = Path(__file__).resolve().parent

PLAYER_README = """Gods Die Here — mobile arena playtest

1. Extract the ZIP on a computer with Python 3.9 or later.
2. On Windows, double-click START - Windows.cmd and allow access on your
   private network if Windows prompts. On Mac or Linux, open this folder in a
   terminal and run: python3 serve_web.py
3. Connect your phone to the same Wi-Fi and open the printed phone URL in
   Safari or Chrome. Keep the server window open while you play.
4. Turn your phone sideways for landscape play.

You can also serve the web folder as a static site. Keep its filenames intact.
"""

WINDOWS_LAUNCHER = """@echo off
cd /d "%~dp0"
set "PYTHON_COMMAND=py -3"
where py >nul 2>&1
if errorlevel 1 set "PYTHON_COMMAND=python"
%PYTHON_COMMAND% serve_web.py
pause
"""

WEB_PRESET = """[preset.0]

name="Mobile Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter="docs/*,tests/*,tools/*"

[preset.0.options]

custom_template/release={release_template}
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=false
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
"""


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot", help="Godot executable")
    parser.add_argument(
        "--release-template",
        type=Path,
        help="matching Godot web_nothreads_release.zip, if it is not installed",
    )
    parser.add_argument(
        "--output", type=Path, default=PROJECT_ROOT / "build" / "mobile-web"
    )
    parser.add_argument("--archive", type=Path, help="ZIP with the build and Wi-Fi launcher")
    options = parser.parse_args()

    output_directory = options.output.resolve()
    release_template = ""
    if options.release_template:
        template_path = options.release_template.resolve()
        if not template_path.is_file():
            parser.error(f"template file does not exist: {template_path}")
        release_template = str(template_path)

    with tempfile.TemporaryDirectory(prefix="gods-die-here-web-") as temporary:
        build_directory = Path(temporary)
        project_directory = build_directory / "project"
        shutil.copytree(
            PROJECT_ROOT,
            project_directory,
            ignore=shutil.ignore_patterns(".git", ".godot", "build"),
        )
        (project_directory / "export_presets.cfg").write_text(
            WEB_PRESET.format(release_template=json.dumps(release_template)),
            encoding="utf-8",
        )

        export_directory = build_directory / "export"
        export_directory.mkdir()
        godot = [options.godot, "--headless", "--path", str(project_directory)]
        subprocess.run([*godot, "--import"], check=True)
        subprocess.run(
            [*godot, "--export-release", "Mobile Web", str(export_directory / "index.html")],
            check=True,
        )
        shutil.copytree(export_directory, output_directory, dirs_exist_ok=True)
        if options.archive:
            archive_path = options.archive.resolve()
            archive_path.parent.mkdir(parents=True, exist_ok=True)
            with ZipFile(archive_path, "w", compression=ZIP_DEFLATED) as archive:
                for file in sorted(export_directory.iterdir()):
                    archive.write(file, f"web/{file.name}")
                archive.write(MOBILE_TOOLS / "serve_web.py", "serve_web.py")
                archive.writestr("START - Windows.cmd", WINDOWS_LAUNCHER.replace("\n", "\r\n"))
                archive.writestr("READ ME.txt", PLAYER_README)
            print(f"Mobile Web archive: {archive_path}")

    print(f"Mobile Web build: {output_directory}")


if __name__ == "__main__":
    main()
