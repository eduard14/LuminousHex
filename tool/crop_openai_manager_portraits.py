#!/usr/bin/env python3
"""Crop OpenAI-generated manager portrait sheets into project PNG assets."""

from __future__ import annotations

import argparse
import re
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SIZE = 256


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def _read_png(path: Path) -> tuple[int, int, bytearray]:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError(f"{path} is not a PNG")

    offset = 8
    width = height = color_type = None
    idat = bytearray()
    while offset < len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload = data[offset + 8 : offset + 8 + length]
        offset += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
            if bit_depth != 8 or interlace != 0:
                raise ValueError(f"{path} uses unsupported PNG settings")
            if color_type not in (2, 6):
                raise ValueError(f"{path} uses unsupported color type {color_type}")
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            break

    if width is None or height is None or color_type is None:
        raise ValueError(f"{path} is missing PNG metadata")

    channels = 4 if color_type == 6 else 3
    bpp = channels
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    rows: list[bytearray] = []
    pos = 0
    previous = bytearray(stride)
    for _ in range(height):
        filter_type = raw[pos]
        pos += 1
        row = bytearray(raw[pos : pos + stride])
        pos += stride
        for index, value in enumerate(row):
            left = row[index - bpp] if index >= bpp else 0
            up = previous[index]
            upper_left = previous[index - bpp] if index >= bpp else 0
            if filter_type == 1:
                row[index] = (value + left) & 0xFF
            elif filter_type == 2:
                row[index] = (value + up) & 0xFF
            elif filter_type == 3:
                row[index] = (value + ((left + up) // 2)) & 0xFF
            elif filter_type == 4:
                row[index] = (value + _paeth(left, up, upper_left)) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"{path} uses unknown PNG filter {filter_type}")
        rows.append(row)
        previous = row

    rgba = bytearray(width * height * 4)
    for y, row in enumerate(rows):
        for x in range(width):
            source = (x * channels)
            target = ((y * width) + x) * 4
            rgba[target : target + 3] = row[source : source + 3]
            rgba[target + 3] = row[source + 3] if channels == 4 else 255
    return width, height, rgba


def _write_png(path: Path, width: int, height: int, rgba: bytearray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    scanlines = bytearray()
    stride = width * 4
    for y in range(height):
        scanlines.append(0)
        start = y * stride
        scanlines.extend(rgba[start : start + stride])

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + kind
            + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
        )

    path.write_bytes(
        b"".join(
            [
                b"\x89PNG\r\n\x1a\n",
                chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)),
                chunk(b"IDAT", zlib.compress(bytes(scanlines), 9)),
                chunk(b"IEND", b""),
            ]
        )
    )


def _sample_bilinear(
    width: int,
    height: int,
    rgba: bytearray,
    x: float,
    y: float,
) -> tuple[int, int, int, int]:
    x = min(max(x, 0), width - 1)
    y = min(max(y, 0), height - 1)
    x0 = int(x)
    y0 = int(y)
    x1 = min(x0 + 1, width - 1)
    y1 = min(y0 + 1, height - 1)
    tx = x - x0
    ty = y - y0

    def pixel(px: int, py: int) -> tuple[int, int, int, int]:
        offset = ((py * width) + px) * 4
        return tuple(rgba[offset : offset + 4])  # type: ignore[return-value]

    c00 = pixel(x0, y0)
    c10 = pixel(x1, y0)
    c01 = pixel(x0, y1)
    c11 = pixel(x1, y1)
    out = []
    for channel in range(4):
        top = c00[channel] + ((c10[channel] - c00[channel]) * tx)
        bottom = c01[channel] + ((c11[channel] - c01[channel]) * tx)
        out.append(round(top + ((bottom - top) * ty)))
    return tuple(out)  # type: ignore[return-value]


def _crop_grid(
    sheet_path: Path,
    ids: list[str],
    output_dir: Path,
    *,
    columns: int = 5,
    rows: int = 4,
) -> None:
    width, height, rgba = _read_png(sheet_path)
    cell_w = width / columns
    cell_h = height / rows
    side = min(cell_w, cell_h) * 0.985
    for index, config_id in enumerate(ids):
        row = index // columns
        col = index % columns
        cx = (col + 0.5) * cell_w
        cy = (row + 0.5) * cell_h
        left = cx - (side / 2)
        top = cy - (side / 2)
        out = bytearray(SIZE * SIZE * 4)
        for y in range(SIZE):
            sy = top + ((y + 0.5) * side / SIZE)
            for x in range(SIZE):
                sx = left + ((x + 0.5) * side / SIZE)
                offset = ((y * SIZE) + x) * 4
                out[offset : offset + 4] = bytes(_sample_bilinear(width, height, rgba, sx, sy))
        _write_png(output_dir / f"{config_id}.png", SIZE, SIZE, out)


def _parse_ids(path: Path, kinds: str) -> list[str]:
    pattern = re.compile(rf"_(?:{kinds})\(\s*'([^']+)'", re.MULTILINE)
    ids: list[str] = []
    seen: set[str] = set()
    for config_id in pattern.findall(path.read_text()):
        if config_id in seen:
            continue
        seen.add(config_id)
        ids.append(config_id)
    return ids


def _parse_enemy_manager_ids(path: Path) -> list[str]:
    text = path.read_text()
    static_ids = dict(
        re.findall(
            r"static final (\w+) = _(?:swarm|titan|phase|regen|gravity|greed|saboteur|volatile|apex)\(\s*'([^']+)'",
            text,
        )
    )
    all_match = re.search(
        r"static final all = <EnemyManagerConfig>\[(.*?)\n  \];",
        text,
        re.DOTALL,
    )
    if not all_match:
        raise ValueError("Could not find EnemyManagerLibrary.all")
    body = all_match.group(1)
    ids: list[str] = []
    seen: set[str] = set()
    for token in re.finditer(
        r"\b([A-Za-z]\w*)\b|_(?:swarm|titan|phase|regen|gravity|greed|saboteur|volatile|apex)\(\s*'([^']+)'",
        body,
    ):
        config_id = token.group(2) or static_ids.get(token.group(1))
        if config_id is None or config_id in seen:
            continue
        seen.add(config_id)
        ids.append(config_id)
    return ids


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--core-a", required=True, type=Path)
    parser.add_argument("--core-b", required=True, type=Path)
    parser.add_argument("--threat-a", required=True, type=Path)
    parser.add_argument("--threat-b", required=True, type=Path)
    parser.add_argument("--columns", type=int, default=5)
    parser.add_argument("--rows", type=int, default=4)
    args = parser.parse_args()

    core_ids = _parse_ids(
        ROOT / "lib/data/card_configs.dart",
        "flow|power|tempo|spectrum|stability|pulse|burst",
    )
    threat_ids = _parse_enemy_manager_ids(ROOT / "lib/data/enemy_manager_configs.dart")
    if len(core_ids) != 40:
        raise SystemExit(f"Expected 40 core manager IDs, found {len(core_ids)}")
    if len(threat_ids) != 40:
        raise SystemExit(f"Expected 40 threat director IDs, found {len(threat_ids)}")

    _crop_grid(
        args.core_a,
        core_ids[:20],
        ROOT / "assets/sprites/managers/core",
        columns=args.columns,
        rows=args.rows,
    )
    _crop_grid(
        args.core_b,
        core_ids[20:],
        ROOT / "assets/sprites/managers/core",
        columns=args.columns,
        rows=args.rows,
    )
    _crop_grid(
        args.threat_a,
        threat_ids[:20],
        ROOT / "assets/sprites/managers/threat",
        columns=args.columns,
        rows=args.rows,
    )
    _crop_grid(
        args.threat_b,
        threat_ids[20:],
        ROOT / "assets/sprites/managers/threat",
        columns=args.columns,
        rows=args.rows,
    )
    print("Generated 80 manager portrait PNG assets.")


if __name__ == "__main__":
    main()
