#!/usr/bin/env python3
"""Import OpenAI-generated sprite sheets into project avatar assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TARGET_SIZE = 512

EQUIPMENT_SETS = (
    "surveyor",
    "ashspike",
    "embertrail",
    "sunplate",
    "thornpath",
    "tideglass",
    "voidloom",
)
EQUIPMENT_SLOTS = ("hat", "top", "pants", "shoes", "accessory")

BASE_OUTPUTS = (
    ("assets/sprites/avatar/base/lumo_idle.png", 0, 0),
    ("assets/sprites/avatar/base/lumo_move.png", 1, 0),
    ("assets/sprites/avatar/base/lumo_boost.png", 2, 0),
    ("assets/sprites/avatar/base/luma_idle.png", 0, 1),
    ("assets/sprites/avatar/base/luma_move.png", 1, 1),
    ("assets/sprites/avatar/base/luma_boost.png", 2, 1),
)

COSMETIC_OUTPUTS = (
    ("assets/sprites/avatar/hair/comet_cowlick.png", 0, 0, 0.92),
    ("assets/sprites/avatar/hair/nebula_sweep.png", 1, 0, 0.92),
    ("assets/sprites/avatar/hair/solar_tufts.png", 2, 0, 0.92),
    ("assets/sprites/avatar/face/joyful_arc.png", 0, 1, 0.82),
    ("assets/sprites/avatar/face/focused_glow.png", 1, 1, 0.82),
    ("assets/sprites/avatar/face/spark_wink.png", 2, 1, 0.82),
)


def _cell_box(
    image: Image.Image,
    columns: int,
    rows: int,
    col: int,
    row: int,
    *,
    inset_ratio: float,
) -> tuple[int, int, int, int]:
    width, height = image.size
    left = round(width * col / columns)
    top = round(height * row / rows)
    right = round(width * (col + 1) / columns)
    bottom = round(height * (row + 1) / rows)
    inset_x = round((right - left) * inset_ratio)
    inset_y = round((bottom - top) * inset_ratio)
    return left + inset_x, top + inset_y, right - inset_x, bottom - inset_y


def _remove_green_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            green_background = g > 70 and g > r + 20 and g > b + 20
            if green_background:
                pixels[x, y] = (r, g, b, 0)
            elif a:
                max_non_green = max(r, b)
                if g > max_non_green + 24:
                    g = max_non_green + 24
                pixels[x, y] = (r, g, b, a)
    return image


def _content_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if bbox is None:
        return 0, 0, image.width, image.height
    pad = max(8, round(max(image.width, image.height) * 0.018))
    left, top, right, bottom = bbox
    return (
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    )


def _fit_to_square(image: Image.Image, content_scale: float) -> Image.Image:
    image = image.crop(_content_bbox(image))
    width, height = image.size
    max_side = max(width, height, 1)
    target_side = round(TARGET_SIZE * content_scale)
    scale = target_side / max_side
    resized = image.resize(
        (max(1, round(width * scale)), max(1, round(height * scale))),
        Image.Resampling.LANCZOS,
    )
    out = Image.new("RGBA", (TARGET_SIZE, TARGET_SIZE), (0, 0, 0, 0))
    out.alpha_composite(
        resized,
        ((TARGET_SIZE - resized.width) // 2, (TARGET_SIZE - resized.height) // 2),
    )
    return out


def _write_cell(
    sheet: Image.Image,
    columns: int,
    rows: int,
    col: int,
    row: int,
    output: Path,
    *,
    content_scale: float,
    inset_ratio: float = 0.035,
) -> None:
    crop = sheet.crop(
        _cell_box(sheet, columns, rows, col, row, inset_ratio=inset_ratio)
    )
    sprite = _fit_to_square(_remove_green_background(crop), content_scale)
    output.parent.mkdir(parents=True, exist_ok=True)
    sprite.save(output)
    print(output.relative_to(ROOT))


def import_base(sheet_path: Path) -> None:
    sheet = Image.open(sheet_path)
    for relative, col, row in BASE_OUTPUTS:
        _write_cell(
            sheet,
            3,
            2,
            col,
            row,
            ROOT / relative,
            content_scale=0.96,
            inset_ratio=0.04,
        )


def import_cosmetics(sheet_path: Path) -> None:
    sheet = Image.open(sheet_path)
    for relative, col, row, content_scale in COSMETIC_OUTPUTS:
        _write_cell(
            sheet,
            3,
            2,
            col,
            row,
            ROOT / relative,
            content_scale=content_scale,
            inset_ratio=0.04,
        )


def import_equipment(sheet_path: Path) -> None:
    sheet = Image.open(sheet_path)
    for col, set_id in enumerate(EQUIPMENT_SETS):
        for row, slot in enumerate(EQUIPMENT_SLOTS):
            _write_cell(
                sheet,
                7,
                5,
                col,
                row,
                ROOT / f"assets/sprites/equipment/{set_id}/{slot}.png",
                content_scale=0.88,
                inset_ratio=0.025,
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-sheet", type=Path, required=True)
    parser.add_argument("--cosmetic-sheet", type=Path, required=True)
    parser.add_argument("--equipment-sheet", type=Path, required=True)
    args = parser.parse_args()

    import_base(args.base_sheet)
    import_cosmetics(args.cosmetic_sheet)
    import_equipment(args.equipment_sheet)


if __name__ == "__main__":
    main()
