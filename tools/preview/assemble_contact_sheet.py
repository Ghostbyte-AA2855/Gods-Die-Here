"""Combine actual-model arena renders and the in-game roster labels."""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

INK = "#e7e1d4"
EMBER = "#c78c6b"
MUTED = "#ababaa"
CARD = "#171717"
EDGE = "#393531"
GROUND = "#111010"
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
    margin, gap, cell = 32, 20, 396
    render_height, row_height = cell, cell + 90
    header = 155
    panel = Image.new("RGB", (2 * margin + 4 * cell + 3 * gap,
                             header + 4 * row_height + 3 * gap + margin), GROUND)
    draw = ImageDraw.Draw(panel)
    title = font("DejaVuSerif-Bold.ttf", 56)
    subtitle = font("DejaVuSans.ttf", 22)
    name = font("DejaVuSerif-Bold.ttf", 22)
    role = font("DejaVuSans-Bold.ttf", 14)
    patron = font("DejaVuSans.ttf", 16)
    draw.text((margin, 22), "GODS DIE HERE", font=title, fill=INK)
    draw.text((margin + 2, 100), "The sixteen champions  /  rendered from the game models",
              font=subtitle, fill=MUTED)
    draw.line((margin, 134, panel.width - margin, 134), fill=EDGE, width=2)

    for index, champion in enumerate(roster):
        x = margin + (index % 4) * (cell + gap)
        y = header + (index // 4) * (row_height + gap)
        draw.rectangle((x, y, x + cell - 1, y + row_height - 1), fill=CARD, outline=EDGE)
        render_path = args.directory / (champion["id"] + ".png")
        with Image.open(render_path) as raw:
            render = raw.convert("RGB").resize((cell - 2, render_height - 2), Image.Resampling.LANCZOS)
        panel.paste(render, (x + 1, y + 1))
        draw.line((x + 1, y + render_height, x + cell - 2, y + render_height), fill=EDGE)
        draw.text((x + 18, y + render_height + 10), champion["class"].upper(), font=role, fill=EMBER)
        draw.text((x + 18, y + render_height + 30), champion["champion"], font=name, fill=INK)
        draw.text((x + 18, y + render_height + 62), "Sworn to " + champion["god"], font=patron, fill=MUTED)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    panel.save(args.output, quality=94, subsampling=0, optimize=True)


if __name__ == "__main__":
    main()
