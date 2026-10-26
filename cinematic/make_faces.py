"""Rebuild the four transparent R6 cinematic face decals with Python stdlib."""
from pathlib import Path
import struct
import zlib

SIZE = 256
OUT = Path(__file__).parent
INK = (36, 28, 32, 255)
CHEEK = (184, 83, 94, 115)
WHITE = (255, 245, 230, 255)


def png(name, pixels):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    raw = b"".join(b"\0" + bytes(pixels[y * SIZE * 4:(y + 1) * SIZE * 4]) for y in range(SIZE))
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    (OUT / f"face_{name}.png").write_bytes(data)


def draw(mode):
    pixels = bytearray(SIZE * SIZE * 4)

    def dot(x, y, color):
        x, y = int(x), int(y)
        if 0 <= x < SIZE and 0 <= y < SIZE:
            i = (y * SIZE + x) * 4
            pixels[i:i + 4] = bytes(color)

    def ellipse(cx, cy, rx, ry, color):
        for y in range(max(0, int(cy - ry)), min(SIZE, int(cy + ry) + 1)):
            for x in range(max(0, int(cx - rx)), min(SIZE, int(cx + rx) + 1)):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                    dot(x, y, color)

    def stroke(x1, y1, x2, y2, width, color=INK):
        count = int(max(abs(x2 - x1), abs(y2 - y1)) * 2)
        for n in range(count + 1):
            u = n / max(1, count)
            ellipse(x1 + (x2 - x1) * u, y1 + (y2 - y1) * u, width, width, color)

    ellipse(69, 157, 20, 9, CHEEK)
    ellipse(187, 157, 20, 9, CHEEK)
    brow_y = 71 if mode in ("shock", "nervous") else 87
    if mode in ("angry", "determined"):
        stroke(49, 84, 98, 101, 6)
        stroke(158, 101, 207, 84, 6)
    else:
        stroke(49, brow_y + (6 if mode == "smile" else 0), 97, brow_y - 4, 5)
        stroke(159, brow_y - 4, 207, brow_y + (6 if mode == "smile" else 0), 5)
    for cx in (78, 178):
        ellipse(cx, 123, 13 if mode not in ("shock", "nervous") else 17, 18 if mode not in ("shock", "nervous") else 22, INK)
        ellipse(cx - 4, 115, 4, 5, WHITE)
        stroke(cx - 18, 111, cx - 12, 108, 2)
        stroke(cx + 12, 108, cx + 18, 111, 2)
    if mode == "shock":
        ellipse(128, 184, 19, 26, INK)
        ellipse(128, 190, 10, 12, (147, 58, 66, 255))
    elif mode == "angry":
        stroke(104, 185, 152, 185, 6)
        stroke(105, 185, 115, 180, 4)
    elif mode == "nervous":
        ellipse(128, 182, 18, 11, INK)
        ellipse(217, 112, 6, 13, (100, 189, 211, 250))
        ellipse(217, 122, 4, 5, (100, 189, 211, 250))
    elif mode == "determined":
        ellipse(128, 181, 29, 12, INK)
        for x in range(105, 151):
            for y in range(174, 179):
                dot(x, y, WHITE)
    elif mode == "smile":
        for x in range(94, 163):
            u = (x - 128) / 34
            ellipse(x, 174 + 13 * (1 - u * u), 3, 3, INK)
    else:
        stroke(107, 184, 150, 180, 4)
    png(mode, pixels)


for expression in ("neutral", "shock", "angry", "smile", "nervous", "determined"):
    draw(expression)
