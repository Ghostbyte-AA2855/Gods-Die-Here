"""Combine actual-model arena renders and the in-game roster labels."""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

INK = "#e6d8bd"
EMBER = "#d49365"
MUTED = "#a89baf"
CARD = "#1c1721"
EDGE = "#453344"
GROUND = "#0e0c12"
FONT_ROOT = Path("/usr/share/fonts/truetype/dejavu")


def font(filename, size):
    try:
        return ImageFont.truetype(str(FONT_ROOT / filename), size)
    except OSError:
        return ImageFont.load_default(size=size)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    roster = json.loads((args.directory / "champions.json").read_text())
    margin, gap, cell, render_height, row_height = 34, 17, 390, 352, 449
    header = 172
    panel = Image.new("RGB", (2 * margin + 4 * cell + 3 * gap,
                             header + 4 * row_height + 3 * gap + margin), GROUND)
    draw = ImageDraw.Draw(panel)
    title = font("DejaVuSerif-Bold.ttf", 53)
    subtitle = font("DejaVuSans.ttf", 22)
    name = font("DejaVuSerif-Bold.ttf", 22)
    role = font("DejaVuSans-Bold.ttf", 13)
    patron = font("DejaVuSans.ttf", 16)
    draw.text((margin, 28), "GODS DIE HERE", font=title, fill=INK)
    draw.text((margin + 2, 101), "The sixteen champions   /   game meshes rendered with studio lighting",
              font=subtitle, fill=MUTED)
    draw.line((margin, 142, panel.width - margin, 142), fill=EDGE, width=2)

    for index, champion in enumerate(roster):
        x = margin + (index % 4) * (cell + gap)
        y = header + (index // 4) * (row_height + gap)
        draw.rounded_rectangle((x, y, x + cell - 1, y + row_height - 1), 10, fill=CARD, outline=EDGE)
        render_path = args.directory / (champion["id"] + ".png")
        render = Image.open(render_path).convert("RGB")
        render.thumbnail((cell - 6, render_height - 6), Image.Resampling.LANCZOS)
        panel.paste(render, (x + (cell - render.width) // 2, y + 4))
        draw.line((x + 16, y + render_height, x + cell - 16, y + render_height), fill=EDGE)
        draw.text((x + 18, y + render_height + 10), champion["class"].upper(), font=role, fill=EMBER)
        draw.text((x + 18, y + render_height + 30), champion["champion"], font=name, fill=INK)
        draw.text((x + 18, y + render_height + 62), "Sworn to " + champion["god"], font=patron, fill=MUTED)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    panel.save(args.output, quality=94, subsampling=0, optimize=True)


if __name__ == "__main__":
    main()
