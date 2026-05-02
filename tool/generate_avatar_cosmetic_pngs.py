#!/usr/bin/env python3
"""Generate transparent PNG placeholder overlays for avatar cosmetics."""

from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SIZE = 512
SCALE = 3
CANVAS = SIZE * SCALE


def _blend(buffer: bytearray, width: int, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if x < 0 or y < 0 or x >= width or y >= width:
        return
    r, g, b, a = color
    if a <= 0:
        return
    index = (y * width + x) * 4
    old_a = buffer[index + 3] / 255
    src_a = a / 255
    out_a = src_a + old_a * (1 - src_a)
    if out_a <= 0:
        return
    for channel, value in enumerate((r, g, b)):
        old = buffer[index + channel] / 255
        src = value / 255
        out = (src * src_a + old * old_a * (1 - src_a)) / out_a
        buffer[index + channel] = max(0, min(255, round(out * 255)))
    buffer[index + 3] = max(0, min(255, round(out_a * 255)))


def _scaled(value: float) -> int:
    return round(value * SCALE)


def _draw_ellipse(
    buffer: bytearray,
    center: tuple[float, float],
    radius: tuple[float, float],
    color: tuple[int, int, int, int],
) -> None:
    cx, cy = _scaled(center[0]), _scaled(center[1])
    rx, ry = max(1, _scaled(radius[0])), max(1, _scaled(radius[1]))
    for y in range(cy - ry, cy + ry + 1):
        dy = (y - cy) / ry
        if abs(dy) > 1:
            continue
        span = int(rx * math.sqrt(max(0, 1 - dy * dy)))
        for x in range(cx - span, cx + span + 1):
            _blend(buffer, CANVAS, x, y, color)


def _draw_line(
    buffer: bytearray,
    start: tuple[float, float],
    end: tuple[float, float],
    thickness: float,
    color: tuple[int, int, int, int],
) -> None:
    x1, y1 = _scaled(start[0]), _scaled(start[1])
    x2, y2 = _scaled(end[0]), _scaled(end[1])
    radius = max(1, _scaled(thickness / 2))
    min_x, max_x = min(x1, x2) - radius, max(x1, x2) + radius
    min_y, max_y = min(y1, y2) - radius, max(y1, y2) + radius
    dx, dy = x2 - x1, y2 - y1
    length_sq = max(1, dx * dx + dy * dy)
    for y in range(min_y, max_y + 1):
        for x in range(min_x, max_x + 1):
            t = max(0, min(1, ((x - x1) * dx + (y - y1) * dy) / length_sq))
            px = x1 + dx * t
            py = y1 + dy * t
            if math.hypot(x - px, y - py) <= radius:
                _blend(buffer, CANVAS, x, y, color)


def _draw_curve(
    buffer: bytearray,
    points: list[tuple[float, float]],
    thickness: float,
    color: tuple[int, int, int, int],
) -> None:
    samples: list[tuple[float, float]] = []
    steps = 34
    if len(points) == 3:
        p0, p1, p2 = points
        for index in range(steps + 1):
            t = index / steps
            mt = 1 - t
            samples.append(
                (
                    mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0],
                    mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1],
                )
            )
    else:
        p0, p1, p2, p3 = points
        for index in range(steps + 1):
            t = index / steps
            mt = 1 - t
            samples.append(
                (
                    mt**3 * p0[0]
                    + 3 * mt * mt * t * p1[0]
                    + 3 * mt * t * t * p2[0]
                    + t**3 * p3[0],
                    mt**3 * p0[1]
                    + 3 * mt * mt * t * p1[1]
                    + 3 * mt * t * t * p2[1]
                    + t**3 * p3[1],
                )
            )
    for first, second in zip(samples, samples[1:]):
        _draw_line(buffer, first, second, thickness, color)


def _draw_spark(buffer: bytearray, center: tuple[float, float], size: float, color: tuple[int, int, int, int]) -> None:
    cx, cy = center
    _draw_line(buffer, (cx, cy - size), (cx, cy + size), size * 0.18, color)
    _draw_line(buffer, (cx - size, cy), (cx + size, cy), size * 0.18, color)
    _draw_line(
        buffer,
        (cx - size * 0.62, cy - size * 0.62),
        (cx + size * 0.62, cy + size * 0.62),
        size * 0.12,
        color,
    )
    _draw_line(
        buffer,
        (cx + size * 0.62, cy - size * 0.62),
        (cx - size * 0.62, cy + size * 0.62),
        size * 0.12,
        color,
    )


def _downsample(buffer: bytearray) -> bytearray:
    out = bytearray(SIZE * SIZE * 4)
    area = SCALE * SCALE
    for y in range(SIZE):
        for x in range(SIZE):
            totals = [0, 0, 0, 0]
            for sy in range(SCALE):
                for sx in range(SCALE):
                    src = ((y * SCALE + sy) * CANVAS + (x * SCALE + sx)) * 4
                    totals[0] += buffer[src]
                    totals[1] += buffer[src + 1]
                    totals[2] += buffer[src + 2]
                    totals[3] += buffer[src + 3]
            dst = (y * SIZE + x) * 4
            for channel in range(4):
                out[dst + channel] = round(totals[channel] / area)
    return out


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )


def _write_png(path: Path, pixels: bytearray) -> None:
    raw = bytearray()
    stride = SIZE * 4
    for y in range(SIZE):
        raw.append(0)
        raw.extend(pixels[y * stride : (y + 1) * stride])
    png = (
        b"\x89PNG\r\n\x1a\n"
        + _png_chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
        + _png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + _png_chunk(b"IEND", b"")
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def _new_canvas() -> bytearray:
    return bytearray(CANVAS * CANVAS * 4)


def comet_cowlick() -> bytearray:
    b = _new_canvas()
    _draw_curve(b, [(230, 164), (238, 96), (279, 72), (300, 142)], 31, (0, 225, 255, 42))
    _draw_curve(b, [(230, 164), (238, 96), (279, 72), (300, 142)], 17, (76, 239, 255, 210))
    _draw_curve(b, [(214, 168), (199, 118), (235, 92)], 12, (164, 247, 255, 190))
    _draw_curve(b, [(286, 154), (324, 111), (349, 152)], 12, (164, 247, 255, 175))
    _draw_spark(b, (278, 74), 18, (255, 255, 255, 230))
    return _downsample(b)


def nebula_sweep() -> bytearray:
    b = _new_canvas()
    _draw_curve(b, [(158, 169), (231, 74), (352, 113), (378, 175)], 44, (156, 86, 255, 48))
    _draw_curve(b, [(158, 169), (231, 74), (352, 113), (378, 175)], 25, (136, 76, 255, 220))
    _draw_curve(b, [(181, 159), (246, 99), (358, 134)], 10, (232, 222, 255, 205))
    _draw_curve(b, [(169, 174), (120, 212), (164, 250)], 19, (94, 47, 214, 180))
    _draw_spark(b, (338, 118), 14, (236, 218, 255, 230))
    return _downsample(b)


def solar_tufts() -> bytearray:
    b = _new_canvas()
    _draw_curve(b, [(214, 168), (180, 102), (216, 78), (247, 147)], 31, (255, 187, 36, 52))
    _draw_curve(b, [(214, 168), (180, 102), (216, 78), (247, 147)], 16, (255, 188, 53, 220))
    _draw_curve(b, [(301, 148), (335, 78), (376, 109), (334, 172)], 31, (255, 187, 36, 52))
    _draw_curve(b, [(301, 148), (335, 78), (376, 109), (334, 172)], 16, (255, 188, 53, 220))
    _draw_curve(b, [(239, 151), (263, 96), (293, 153)], 12, (255, 245, 186, 215))
    _draw_spark(b, (263, 96), 17, (255, 255, 218, 245))
    return _downsample(b)


def joyful_arc() -> bytearray:
    b = _new_canvas()
    _draw_ellipse(b, (164, 214), (68, 50), (3, 10, 22, 138))
    _draw_ellipse(b, (348, 214), (68, 50), (3, 10, 22, 138))
    _draw_curve(b, [(100, 224), (164, 156), (232, 224)], 32, (73, 214, 255, 56))
    _draw_curve(b, [(100, 224), (164, 156), (232, 224)], 12, (166, 245, 255, 232))
    _draw_curve(b, [(280, 224), (348, 156), (414, 224)], 32, (73, 214, 255, 56))
    _draw_curve(b, [(280, 224), (348, 156), (414, 224)], 12, (166, 245, 255, 232))
    _draw_curve(b, [(216, 328), (256, 360), (300, 328)], 10, (188, 250, 255, 214))
    return _downsample(b)


def focused_glow() -> bytearray:
    b = _new_canvas()
    _draw_ellipse(b, (166, 224), (66, 82), (2, 8, 20, 142))
    _draw_ellipse(b, (346, 224), (66, 82), (2, 8, 20, 142))
    _draw_ellipse(b, (166, 224), (44, 68), (72, 220, 255, 58))
    _draw_ellipse(b, (166, 224), (22, 46), (224, 252, 255, 242))
    _draw_ellipse(b, (346, 224), (44, 68), (72, 220, 255, 58))
    _draw_ellipse(b, (346, 224), (22, 46), (224, 252, 255, 242))
    _draw_line(b, (218, 326), (294, 326), 10, (180, 246, 255, 208))
    return _downsample(b)


def spark_wink() -> bytearray:
    b = _new_canvas()
    _draw_ellipse(b, (164, 222), (68, 48), (4, 7, 20, 138))
    _draw_ellipse(b, (346, 222), (70, 70), (4, 7, 20, 138))
    _draw_curve(b, [(98, 228), (164, 170), (232, 228)], 30, (168, 112, 255, 56))
    _draw_curve(b, [(98, 228), (164, 170), (232, 228)], 12, (222, 198, 255, 235))
    _draw_spark(b, (346, 216), 56, (232, 215, 255, 236))
    _draw_ellipse(b, (346, 216), (15, 15), (255, 255, 255, 238))
    _draw_curve(b, [(210, 330), (250, 355), (304, 318)], 10, (220, 190, 255, 216))
    return _downsample(b)


ASSETS = {
    "assets/sprites/avatar/hair/comet_cowlick.png": comet_cowlick,
    "assets/sprites/avatar/hair/nebula_sweep.png": nebula_sweep,
    "assets/sprites/avatar/hair/solar_tufts.png": solar_tufts,
    "assets/sprites/avatar/face/joyful_arc.png": joyful_arc,
    "assets/sprites/avatar/face/focused_glow.png": focused_glow,
    "assets/sprites/avatar/face/spark_wink.png": spark_wink,
}


def main() -> None:
    for relative, factory in ASSETS.items():
        _write_png(ROOT / relative, factory())
        print(relative)


if __name__ == "__main__":
    main()
