#!/usr/bin/env python3
"""TEST_01 §8 B: вырезать область скриншота и увеличить без сглаживания (nearest).

python crop_zoom.py <in.png> <x> <y> <w> <h> <out.png> [--scale 8]
"""
import argparse

from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument('src')
ap.add_argument('x', type=int)
ap.add_argument('y', type=int)
ap.add_argument('w', type=int)
ap.add_argument('h', type=int)
ap.add_argument('dst')
ap.add_argument('--scale', type=int, default=8)
a = ap.parse_args()

im = Image.open(a.src).crop((a.x, a.y, a.x + a.w, a.y + a.h))
im.resize((a.w * a.scale, a.h * a.scale), Image.NEAREST).save(a.dst)
print(f'{a.dst}: {a.w}×{a.h} -> {a.w * a.scale}×{a.h * a.scale}')
