#!/usr/bin/env python3
"""TEST_01: палитра-атлас, варианты, образцы, превью, самопроверка, _build_info.json.

Порт palette_lib.js + gen_samples.js. Порядок операций с плавающей точкой и округление
(Math.round = floor(x + 0.5)) повторяют JS, чтобы пиксели совпадали с JS-сборкой.
PNG пишется вручную (фильтр 0, zlib по умолчанию) — как png() в palette_lib.js.

Запуск: python3 gen_palette.py [--out <папка assets>]
"""
import argparse
import hashlib
import json
import math
import struct
import sys
import zlib
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

import numpy as np
import PIL
from PIL import Image

import gen_test_mesh

SEED = 20261030
SIZE = 512
CELL = 32


def jround(x):
    return math.floor(x + 0.5)


# ---------- OKLab (§2) ----------

def s2l(c):
    c /= 255
    return c / 12.92 if c <= 0.04045 else math.pow((c + 0.055) / 1.055, 2.4)


def l2s(c):
    c = 12.92 * c if c <= 0.0031308 else 1.055 * math.pow(c, 1 / 2.4) - 0.055
    return c * 255


def rgb2lab(rgb):
    r, g, b = (s2l(v) for v in rgb)
    l = math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m = math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s = math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    return [0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s]


def lab2lin(lab):
    L, a, b = lab
    l = math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3)
    m = math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3)
    s = math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3)
    return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s]


def in_gamut(v):
    return all(-1e-7 <= x <= 1 + 1e-7 for x in v)


def lab2rgb(lab):
    """OKLab -> sRGB; вне охвата — уменьшение C бинарным поиском при тех же L и h."""
    L, a, b = lab
    L = max(0, min(L, 1))
    C, h = math.hypot(a, b), math.atan2(b, a)
    if not in_gamut(lab2lin([L, a, b])):
        lo, hi = 0, C
        for _ in range(60):
            mid = (lo + hi) / 2
            if in_gamut(lab2lin([L, mid * math.cos(h), mid * math.sin(h)])):
                lo = mid
            else:
                hi = mid
        C = lo
    return [jround(l2s(max(0, min(1, x)))) for x in lab2lin([L, C * math.cos(h), C * math.sin(h)])]


def hex2rgb(h):
    return [int(h[i:i + 2], 16) for i in (1, 3, 5)]


def rgb2hex(v):
    return '#' + ''.join(f'{x:02X}' for x in v)


def hex2lab(h):
    return rgb2lab(hex2rgb(h))


def dE(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2])


def path(stops, n):
    """n точек, равномерно по длине ломаной в OKLab."""
    P = [hex2lab(s) for s in stops]
    seg = [dE(P[i], P[i + 1]) for i in range(len(P) - 1)]
    tot = sum(seg)
    out = []
    for j in range(n):
        t, i = tot * j / (n - 1), 0
        while i < len(seg) - 1 and t > seg[i] + 1e-12:
            t -= seg[i]
            i += 1
        f = min(1, t / seg[i]) if seg[i] else 0
        out.append(rgb2hex(lab2rgb([x + (P[i + 1][q] - x) * f for q, x in enumerate(P[i])])))
    return out


def op(rgb, mix_hex, t, cm, lm):
    """Смешивание -> C × cm -> L × lm (§2)."""
    lab = rgb2lab(rgb)
    if mix_hex:
        m = hex2lab(mix_hex)
        lab = [x + (m[i] - x) * t for i, x in enumerate(lab)]
    L, a, b = lab
    a *= cm
    b *= cm
    L = min(1, L * lm)
    return lab2rgb([L, a, b])


# ---------- Палитра (§3) ----------

FAMILIES = [
    ('neutral', ['#111111', '#F5F2EA']),
    ('sand', ['#7A5A3A', '#D9B98A', '#F2DFB4']),
    ('terracotta', ['#5C2E22', '#B5603F', '#E8A27C']),
    ('rust', ['#4A2412', '#9C4A1E', '#D98B4A']),
    ('wood', ['#3B2615', '#C9A274']),
    ('asphalt', ['#23262A', '#A7ABAE']),
    ('metal', ['#2E3A44', '#D7E0E6']),
    ('greenery', ['#2F3B1E', '#B9C27A']),
    ('water', ['#1E4B5A', '#BFE6EE']),
]
FADED = [('red', '#8E3B32', '#D98C7F'), ('blue', '#2F4A6B', '#8FA9C4'),
         ('yellow', '#B08A2E', '#E8CF7A'), ('teal', '#2E6B66', '#8CC4BC')]
SIGNAL = [('orange', ['#D06C00', '#FF8A1F', '#FFB17B', '#FFCEAE']),
          ('red', ['#C30006', '#E5352B', '#FF7464', '#FFACA0']),
          ('green', ['#009D39', '#3FBF5A', '#5FDB75', '#78F48C']),
          ('yellow', ['#D1A800', '#FFD23F', '#FFE189', '#FFECB6'])]
SIGNAL_TONES = ['dark', 'base', 'light', 'lighter']
ROW11 = [('skin_1', '#4A2C1D'), ('skin_2', '#6B4128'), ('skin_3', '#8D5A3B'), ('skin_4', '#B57E57'),
         ('skin_5', '#D7A57F'), ('skin_6', '#EFCDB0'), ('denim_1', '#1F2E45'), ('denim_2', '#2F4566'),
         ('denim_3', '#4F6A8F'), ('denim_4', '#7F98B8'), ('khaki_dark', '#5B5636'), ('khaki', '#8A8455'),
         ('khaki_light', '#B9B282'), ('cloth_dark', '#4D4440'), ('cloth', '#7A6E66'), ('cloth_light', '#A89C92')]
ROW12 = [('weapon_steel_shadow', '#1C1F22'), ('weapon_steel', '#2E3338'), ('weapon_steel_bevel', '#454C53'),
         ('weapon_steel_worn', '#6B737A'), ('weapon_plastic_black', '#151515'), ('weapon_plastic_dark', '#2A2A2A'),
         ('weapon_plastic_olive', '#3F3A33'), ('weapon_wood_dark', '#4A2E1C'), ('weapon_wood', '#6E4428'),
         ('weapon_wood_light', '#9A6A40'), ('weapon_brass_dark', '#8C6A2A'), ('weapon_brass', '#C9A24A'),
         ('weapon_brass_hi', '#E6CF8A'), ('weapon_wrap_olive', '#3A4426'), ('weapon_strap', '#6B5A44'),
         ('weapon_sight', '#FF8A1F')]
ROW13 = [('armor_paper_white', '#F2EEE3'), ('armor_paper_cream', '#DCD6C8'), ('armor_paper_aged', '#BDB6A6'),
         ('armor_news_dark', '#8F897C'), ('armor_news', '#A8A49B'), ('armor_news_light', '#C8C4BB'),
         ('armor_cover_magenta', '#D6336C'), ('armor_cover_cyan', '#2A9FD6'), ('armor_cover_yellow', '#F2C230'),
         ('armor_cover_red', '#D9412B'), ('armor_cover_green', '#3A8F4E'), ('armor_cover_navy', '#23233A'),
         ('armor_tape', '#B2BCC6'), ('armor_tape_dark', '#8D9399'), ('armor_twine', '#C9B48A'),
         ('armor_twine_dark', '#8A7550')]
GRADS = [('grad_sand_terracotta', '#F2DFB4', '#B5603F'), ('grad_rock', '#D9B98A', '#5C2E22'),
         ('grad_asphalt', '#A7ABAE', '#23262A'), ('grad_wood', '#C9A274', '#3B2615'),
         ('grad_metal', '#D7E0E6', '#2E3A44'), ('grad_greenery', '#B9C27A', '#2F3B1E'),
         ('grad_water', '#BFE6EE', '#1E4B5A'), ('grad_sky_haze', '#8FC7E8', '#F2DFB4')]

# Группы для проверки различимости: соседние внутри группы (строки 0–11)
ROW_GROUPS = {r: [range(16)] for r in range(9)}
ROW_GROUPS[9] = [range(0, 4), range(4, 8), range(8, 12), range(12, 16)]
ROW_GROUPS[10] = [range(0, 4), range(4, 8), range(8, 12), range(12, 16)]
ROW_GROUPS[11] = [range(0, 6), range(6, 10), range(10, 13), range(13, 16)]
WEAPON_SKIN_GROUPS = [range(0, 4), range(4, 7), range(7, 10), range(13, 15)]

VARIANTS = {
    'T_Palette_WeaponSkin_Gold': {12: {0: '#5A4214', 1: '#8C6A22', 2: '#C9A040', 3: '#F0D27A',
                                       4: '#141210', 5: '#22201C', 6: '#302C26',
                                       7: '#2A1A10', 8: '#3E2614', 9: '#5A3A20'}},
    'T_Palette_WeaponSkin_Arctic': {12: {0: '#6F7C86', 1: '#9AA7B0', 2: '#C4CFD6', 3: '#E8EEF2',
                                         4: '#D9DEE2', 5: '#BFC6CC', 6: '#A3ACB3',
                                         7: '#B7C2C9', 8: '#CCD6DC', 9: '#E1E8EC',
                                         13: '#8FA9C4', 14: '#5E7A96'}},
}


def build_cells():
    cells = []
    for fam, stops in FAMILIES:
        cells.append([(f'{fam}_{c:02}', h) for c, h in enumerate(path(stops, 16))])
    row = []
    for name, a, b in FADED:
        row += [(f'faded_{name}_{i}', h) for i, h in enumerate(path([a, b], 4))]
    cells.append(row)
    cells.append([(f'signal_{name}_{t}', h) for name, hs in SIGNAL for t, h in zip(SIGNAL_TONES, hs)])
    cells += [ROW11, ROW12, ROW13]
    return cells


def grad_rows(frm, to):
    A, B = hex2lab(frm), hex2lab(to)
    return [lab2rgb([A[q] + (B[q] - A[q]) * y / 63 for q in range(3)]) for y in range(64)]


def render_palette(cells):
    im = np.zeros((SIZE, SIZE, 3), np.uint8)
    for r, row in enumerate(cells):
        for c, (_, h) in enumerate(row):
            im[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = hex2rgb(h)
    for s, (_, frm, to) in enumerate(GRADS):
        for y, rgb in enumerate(grad_rows(frm, to)):
            im[448 + y, s * 64:(s + 1) * 64] = rgb
    return im


def apply_op(main, rows, *args):
    """Операция §4 над округлёнными цветами основной палитры; строки 14–15 — построчно."""
    im = main.copy()
    cache = {}
    for r in rows:
        if r < 14:
            for c in range(16):
                rgb = tuple(int(v) for v in main[r * CELL, c * CELL])
                im[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = cache.setdefault(rgb, op(rgb, *args))
        else:
            for y in range(r * CELL, (r + 1) * CELL):
                for s in range(8):
                    rgb = tuple(int(v) for v in main[y, s * 64])
                    im[y, s * 64:(s + 1) * 64] = cache.setdefault(rgb, op(rgb, *args))
    return im


def build_variants(main):
    out = {
        'T_Palette_Worn': apply_op(main, [r for r in range(16) if r != 10], '#D9B98A', 0.20, 0.75, 1.05),
        'T_Palette_Armor_State2': apply_op(main, [13], None, 0, 0.70, 0.90),
        'T_Palette_Armor_State3': apply_op(main, [13], '#5A4632', 0.25, 0.45, 0.75),
    }
    for name, rows in VARIANTS.items():
        im = main.copy()
        for r, cols in rows.items():
            for c, h in cols.items():
                im[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = hex2rgb(h)
        out[name] = im
    return out


def r6(x):
    """Как +x.toFixed(6) в JS; целые — без .0, как JSON.stringify."""
    v = float(Decimal(x).quantize(Decimal('0.000001'), ROUND_HALF_UP))
    return int(v) if v == int(v) else v


def palette_json(cells):
    entries = []
    for r, row in enumerate(cells):
        for c, (name, h) in enumerate(row):
            x, y = c * CELL, r * CELL
            entries.append({
                'name': name, 'type': 'solid', 'row': r, 'col': c, 'hex': h,
                'px_rect': [x, y, CELL, CELL],
                'uv_center': [r6((x + 16) / SIZE), r6(1 - (y + 16) / SIZE)],
                'uv_safe_rect': [r6((x + 6) / SIZE), r6(1 - (y + 26) / SIZE),
                                 r6((x + 26) / SIZE), r6(1 - (y + 6) / SIZE)],
            })
    for s, (name, frm, to) in enumerate(GRADS):
        x, y = s * 64, 448
        entries.append({
            'name': name, 'type': 'gradient', 'strip': s, 'from': frm, 'to': to,
            'direction': 'top_to_bottom', 'px_rect': [x, y, 64, 64],
            'uv_rect': [r6(x / SIZE), r6(1 - (y + 64) / SIZE), r6((x + 64) / SIZE), r6(1 - y / SIZE)],
            'uv_safe_rect': [r6((x + 6) / SIZE), r6(1 - (y + 58) / SIZE),
                             r6((x + 58) / SIZE), r6(1 - (y + 6) / SIZE)],
        })
    return {'size': [SIZE, SIZE], 'uv_convention': 'blender_obj_v_up',
            'uv_rect_format': '[u_min, v_min, u_max, v_max]', 'entries': entries}


# ---------- Образцы (§5), порт gen_samples.js ----------

def rng(seed):
    """mulberry32, как в gen_samples.js."""
    s = seed & 0xFFFFFFFF
    M = 0xFFFFFFFF

    def R():
        nonlocal s
        s = (s + 0x6D2B79F5) & M
        t = s
        t = ((t ^ (t >> 15)) * (t | 1)) & M
        t = (t ^ ((t + (((t ^ (t >> 7)) * (t | 61)) & M)) & M)) & M
        return ((t ^ (t >> 14)) & M) / 4294967296
    return R


class Img:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.d = np.zeros((h, w, 4), np.uint8)


def blend_at(im, ys, xs, rgb, a):
    """Векторный blend(): каждый пиксель из (ys, xs) — один раз, a > 0."""
    d = im.d[ys, xs].astype(np.float64)
    sa = a / 255
    da = d[:, 3] / 255
    oa = sa + da * (1 - sa)
    for k in range(3):
        im.d[ys, xs, k] = np.floor((rgb[k] * sa + d[:, k] * da * (1 - sa)) / oa + 0.5)
    im.d[ys, xs, 3] = np.floor(oa * 255 + 0.5)


SS = [0.125, 0.375, 0.625, 0.875]


def fill_shape(im, inside, bbox, rgb, alpha=255):
    x0, y0, x1, y1 = (math.floor(v) for v in bbox)
    xs = np.arange(max(0, x0), min(im.w - 1, x1 + 1) + 1, dtype=np.float64)
    ys = np.arange(max(0, y0), min(im.h - 1, y1 + 1) + 1, dtype=np.float64)
    if not len(xs) or not len(ys):
        return
    X, Y = np.meshgrid(xs, ys)
    n = np.zeros(X.shape, np.int64)
    with np.errstate(divide='ignore', invalid='ignore'):
        for sy in SS:
            for sx in SS:
                n += inside(X + sx, Y + sy)
    m = n > 0
    blend_at(im, Y[m].astype(int), X[m].astype(int), rgb, alpha * n[m] / 16)


def poly_in(P):
    def inside(x, y):
        c = np.zeros(x.shape, bool)
        j = len(P) - 1
        for i in range(len(P)):
            (xi, yi), (xj, yj) = P[i], P[j]
            c ^= ((yi > y) != (yj > y)) & (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
            j = i
        return c
    return inside


def bb(P):
    return [min(p[0] for p in P), min(p[1] for p in P), max(p[0] for p in P), max(p[1] for p in P)]


def fill_poly(im, P, rgb, a=255):
    fill_shape(im, poly_in(P), bb(P), rgb, a)


def seg(im, a, b, w, rgb, alpha):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    L2 = dx * dx + dy * dy or 1

    def inside(x, y):
        t = np.clip(((x - ax) * dx + (y - ay) * dy) / L2, 0, 1)
        return np.hypot(x - ax - t * dx, y - ay - t * dy) <= w / 2
    fill_shape(im, inside, [min(ax, bx) - w, min(ay, by) - w, max(ax, bx) + w, max(ay, by) + w], rgb, alpha)


def _nb_sum(arr):
    """Сумма по окну 3×3 (за краем — 0)."""
    p = np.pad(arr, [(1, 1), (1, 1)] + [(0, 0)] * (arr.ndim - 2))
    h, w = arr.shape[:2]
    return sum(p[1 + oy:1 + oy + h, 1 + ox:1 + ox + w] for oy in (-1, 0, 1) for ox in (-1, 0, 1))


def bleed(im):
    """Ореолы (§5): RGB под прозрачным = среднее заполненных соседей 3×3, волнами до заполнения."""
    filled = im.d[..., 3] > 0
    rgb = im.d[..., :3].astype(np.int64)
    while True:
        n = _nb_sum(filled.astype(np.int64))
        front = ~filled & (n > 0)
        if not front.any():
            break
        s = _nb_sum(rgb * filled[..., None])
        vals = np.floor(s[front] / n[front][:, None] + 0.5).astype(np.int64)
        rgb[front] = vals
        filled |= front
    im.d[..., :3] = rgb


def lab_arr(rgb):
    """rgb2lab для массива (N, 3) — только для проверок."""
    c = rgb / 255
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    r, g, b = c[:, 0], c[:, 1], c[:, 2]
    l = np.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m = np.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s = np.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    return np.stack([0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                     1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                     0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s], 1)


def halo_check(d):
    """Макс. ΔE_OK прозрачного пикселя у непрозрачных до среднего цвета этих соседей."""
    op_ = (d[..., 3] > 0).astype(np.int64)
    n = _nb_sum(op_)
    m = (op_ == 0) & (n > 0)
    if not m.any():
        return 0.0
    s = _nb_sum(d[..., :3].astype(np.int64) * op_[..., None])
    mean = s[m] / n[m][:, None]
    return float(np.max(np.linalg.norm(lab_arr(d[m][:, :3].astype(np.float64)) - lab_arr(mean), axis=1)))


def build_samples(C):
    out = {}

    im = Img(1024, 1024)

    def band(c, wid, col):
        h = wid / 2
        fill_poly(im, [[c - h - 300, 1064], [c + h - 300, 1064], [c + h + 300, -40], [c - h + 300, -40]], col)
    band(430, 120, C['neutral_15'])
    band(600, 60, C['signal_red_base'])
    cx, cy, R_, r = 770, 720, 150, 60
    P = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        rr = r if k % 2 else R_
        P.append([cx + rr * math.cos(a), cy + rr * math.sin(a)])
    fill_poly(im, P, C['signal_yellow_base'])
    bleed(im)
    out['T_VehicleSkin_Test'] = (im, 4)

    im = Img(512, 512)
    R = rng(SEED)
    tongues = []
    x = 40
    while x < 440:
        wd = 56 + R() * 36
        tongues.append({'x': x, 'wd': wd, 'h': 150 + R() * 190, 'lean': (R() - 0.3) * 60})
        x += wd * 0.66

    def layer(k):
        bot = 488 - 10 * k
        base = bot - 24
        L, Rr = 40 + 16 * k, 472 - 16 * k
        P = [[L, bot]]
        for t in tongues:
            x0 = max(L, t['x'] + t['wd'] * 0.16 * k)
            x1 = min(Rr, t['x'] + t['wd'] * (1 - 0.16 * k))
            if x1 - x0 < 10:
                continue
            top = base - t['h'] * (1 - 0.24 * k)
            P.append([x0, base])
            P.append([x0 + (x1 - x0) * 0.3 + t['lean'] * 0.4, (base + top) / 2])
            P.append([(x0 + x1) / 2 + t['lean'], top])
            P.append([x0 + (x1 - x0) * 0.78 + t['lean'] * 0.3, (base + top) / 2 + 12])
            P.append([x1, base])
        P.append([Rr, bot])
        return P
    for k, c in enumerate([C['signal_red_dark'], C['signal_orange_base'],
                           C['signal_yellow_base'], C['signal_yellow_lighter']]):
        fill_poly(im, layer(k), c)
    bleed(im)
    out['T_Sticker_Flames_01'] = (im, 4)

    im = Img(256, 128)

    def always(x, y):
        return np.ones(x.shape, bool)
    fill_shape(im, always, [0, 0, 255, 127], C['neutral_02'])

    def rr_(x, y, w, h, rad, col):
        def inside(px, py):
            qx = np.maximum(x + rad, np.minimum(px, x + w - rad))
            qy = np.maximum(y + rad, np.minimum(py, y + h - rad))
            return np.hypot(px - qx, py - qy) <= rad
        fill_shape(im, inside, [x, y, x + w, y + h], col)
    rr_(4, 4, 248, 120, 12, C['neutral_15'])
    rr_(10, 10, 236, 108, 8, C['neutral_02'])
    rr_(14, 14, 228, 100, 6, C['neutral_15'])
    for sx in (40, 216):
        fill_shape(im, lambda x, y, sx=sx: np.hypot(x - sx, y - 26) <= 4.5, [sx - 6, 20, sx + 6, 32], C['metal_08'])
    G = {'T': ['11111', '00100', '00100', '00100', '00100', '00100', '00100'],
         'R': ['11110', '10001', '10001', '11110', '10100', '10010', '10001'],
         '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
         '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
         '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110']}
    text, cw, chh, gap = 'TR 508', 6, 8, 6
    w = sum(cw * 3 if ch == ' ' else 5 * cw + gap for ch in text) - gap
    px, py = jround(128 - w / 2), jround(70 - 3.5 * chh)
    for ch in text:
        if ch == ' ':
            px += cw * 3
            continue
        for ry, row in enumerate(G[ch]):
            for rx, bit in enumerate(row):
                if bit == '1':
                    fill_shape(im, always, [px + rx * cw, py + ry * chh, px + rx * cw + cw - 1,
                                            py + ry * chh + chh - 1], C['neutral_01'])
        px += 5 * cw + gap
    out['T_Plate_01'] = (im, 3)

    im = Img(512, 512)
    R = rng(SEED + 7)
    ox, oy, N = 200, 220, 13
    rays = []
    for k in range(N):
        a = k / N * 2 * math.pi + R() * 0.35
        pts = [[ox, oy]]
        r, ang = 0, a
        while r < 520:
            r += 30 + R() * 40
            ang += (R() - 0.5) * 0.25
            pts.append([ox + r * math.cos(ang), oy + r * math.sin(ang)])
        rays.append(pts)
    crack = C['neutral_15']
    for p in rays:
        for i in range(len(p) - 1):
            seg(im, p[i], p[i + 1], max(1.2, 3.2 - i * 0.4), crack, 215)

    def dist(q, ring):
        return abs(math.hypot(q[0] - ox, q[1] - oy) - ring)
    for ring in (38, 85, 150, 230):
        for k in range(N):
            if R() < 0.3:
                continue

            def pick(p):
                b = p[1]
                for q in p:
                    if dist(q, ring) < dist(b, ring):
                        b = q
                return b
            a, b = pick(rays[k]), pick(rays[(k + 1) % N])
            m = [(a[0] + b[0]) / 2 + (R() - 0.5) * 14, (a[1] + b[1]) / 2 + (R() - 0.5) * 14]
            seg(im, a, m, 1.6, crack, 190)
            seg(im, m, b, 1.6, crack, 190)
    fill_shape(im, lambda x, y: np.hypot(x - ox, y - oy) <= 9, [ox - 10, oy - 10, ox + 10, oy + 10], crack, 235)
    ys, xs, al = [], [], []
    for y in range(512):
        for x in range(512):
            e = min(x, y, 511 - x, 511 - y)
            if e > 60:
                continue
            a = jround((1 - e / 60) ** 2 * 70 * (0.55 + 0.45 * R()))
            if a > 0:
                ys.append(y)
                xs.append(x)
                al.append(a)
    blend_at(im, np.array(ys), np.array(xs), C['sand_10'], np.array(al, np.float64))
    bleed(im)
    out['T_Glass_Cracked_01'] = (im, 4)
    return out


# ---------- Превью: свой блочный шрифт 5×7 (без системных шрифтов) ----------

FONT = {
    'A': '01110100011000111111100011000110001', 'B': '11110100011000111110100011000111110',
    'C': '01110100011000010000100001000101110', 'D': '11110100011000110001100011000111110',
    'E': '11111100001000011110100001000011111', 'F': '11111100001000011110100001000010000',
    'G': '01110100011000010111100011000101111', 'H': '10001100011000111111100011000110001',
    'I': '01110001000010000100001000010001110', 'J': '00111000100001000010000101001001100',
    'K': '10001100101010011000101001001010001', 'L': '10000100001000010000100001000011111',
    'M': '10001110111010110101100011000110001', 'N': '10001100011100110101100111000110001',
    'O': '01110100011000110001100011000101110', 'P': '11110100011000111110100001000010000',
    'Q': '01110100011000110001101011001001101', 'R': '11110100011000111110101001001010001',
    'S': '01111100001000001110000010000111110', 'T': '11111001000010000100001000010000100',
    'U': '10001100011000110001100011000101110', 'V': '10001100011000110001100010101000100',
    'W': '10001100011000110101101011010101010', 'X': '10001100010101000100010101000110001',
    'Y': '10001100010101000100001000010000100', 'Z': '11111000010001000100010001000011111',
    '0': '01110100011001110101110011000101110', '1': '00100011000010000100001000010001110',
    '2': '01110100010000100010001000100011111', '3': '11111000100010000010000011000101110',
    '4': '00010001100101010010111110001000010', '5': '11111100001111000001000011000101110',
    '6': '00110010001000011110100011000101110', '7': '11111000010001000100010000100001000',
    '8': '01110100011000101110100011000101110', '9': '01110100011000101111000010001001100',
    '_': '00000000000000000000000000000011111', '.': '00000000000000000000000000110001100',
    '-': '00000000000000011111000000000000000', ' ': '0' * 35,
}


def draw_text(canvas, x, y, text, scale=2, col=(30, 30, 30)):
    for ch in text.upper():
        g = FONT.get(ch, FONT[' '])
        for i, bit in enumerate(g):
            if bit == '1':
                gx, gy = x + (i % 5) * scale, y + (i // 5) * scale
                canvas[gy:gy + scale, gx:gx + scale] = col
        x += 6 * scale


def build_preview(images):
    """Контактный лист: плитки 256×256 (nearest), RGBA — на шахматке, подпись снизу."""
    T, PAD, LAB = 256, 56, 40  # PAD: подпись в 25 символов (×12 px) не залезает на соседа
    names = list(images)
    cols = 5
    rows = (len(names) + cols - 1) // cols
    W, H = cols * (T + PAD) + PAD, rows * (T + LAB + PAD) + PAD
    canvas = np.full((H, W, 3), 236, np.uint8)
    yy, xx = np.mgrid[0:T, 0:T]
    checker = np.repeat(np.where((yy // 16 + xx // 16) % 2 == 0, 200, 150).astype(np.uint8)[..., None], 3, 2)
    for i, name in enumerate(names):
        arr = images[name]
        h, w = arr.shape[:2]
        k = min(T / w, T / h)
        tw, th = max(1, round(w * k)), max(1, round(h * k))
        res = np.array(Image.fromarray(arr).resize((tw, th), Image.NEAREST))
        tile = checker.copy()
        oy, ox = (T - th) // 2, (T - tw) // 2
        if res.shape[2] == 4:
            a = res[..., 3:4] / 255
            reg = tile[oy:oy + th, ox:ox + tw]
            tile[oy:oy + th, ox:ox + tw] = np.floor(res[..., :3] * a + reg * (1 - a) + 0.5)
        else:
            tile[oy:oy + th, ox:ox + tw] = res
        X = PAD + (i % cols) * (T + PAD)
        Y = PAD + (i // cols) * (T + LAB + PAD)
        canvas[Y:Y + T, X:X + T] = tile
        draw_text(canvas, X, Y + T + 6, name[2:] if name.startswith('T_') else name)
        draw_text(canvas, X, Y + T + 24, f'{w}X{h} {"RGBA" if arr.shape[2] == 4 else "RGB"}')
    return canvas


# ---------- PNG как в palette_lib.js: фильтр 0, zlib по умолчанию ----------

def png_bytes(arr):
    h, w, ch = arr.shape
    raw = b''.join(b'\x00' + arr[y].tobytes() for y in range(h))

    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 6 if ch == 4 else 2, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')


# ---------- Самопроверка (§7) ----------

class Report:
    def __init__(self):
        self.lines = []
        self.fails = 0

    def add(self, check, file, status, detail=''):
        self.fails += status == 'FAIL'
        self.lines.append(f'{check} | {file} | {status} | {detail}')


def cell_rgb(im, r, c):
    return [int(v) for v in im[r * CELL, c * CELL]]


def check_uniform(rep, im, fname):
    bad = [(r, c) for r in range(14) for c in range(16)
           if not (im[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] == im[r * CELL, c * CELL]).all()]
    rep.add('ячейки однородны', fname, 'FAIL' if bad else 'OK', ' '.join(map(str, bad)))


def check_distinct(rep, im, fname, rows, thr_groups, thr_any, names):
    labs = {(r, c): rgb2lab(cell_rgb(im, r, c)) for r in rows for c in range(16)}
    for r in rows:
        bad, mn = [], 9.0
        if r >= 12:
            thr = thr_any
            pairs = [(a, b) for a in range(16) for b in range(a + 1, 16)]
        else:
            thr = thr_groups
            pairs = [(g[i], g[i + 1]) for g in ROW_GROUPS[r] for i in range(len(g) - 1)]
        for a, b in pairs:
            e = dE(labs[(r, a)], labs[(r, b)])
            mn = min(mn, e)
            if e < thr:
                bad.append(f'{names[r][a]}/{names[r][b]}:{e:.4f}')
        rep.add(f'различимость строка {r}', fname, 'FAIL' if bad else 'OK', f'min {mn:.4f} ' + ' '.join(bad))


def selfcheck(main, variants, pal, cells, samples, tools_dir):
    rep = Report()
    names = [[n for n, _ in row] for row in cells]
    F = 'T_Palette_Main.png'
    rep.add('размер/режим', F, 'OK' if main.shape == (512, 512, 3) else 'FAIL', f'{main.shape}')
    check_uniform(rep, main, F)
    check_distinct(rep, main, F, range(14), 0.02, 0.03, names)
    given = {**{f'signal_{n}_{t}': h for n, hs in SIGNAL for t, h in zip(SIGNAL_TONES, hs)},
             **dict(ROW11), **dict(ROW12), **dict(ROW13)}
    bad = [n for r in range(10, 14) for c, n in enumerate(names[r]) if rgb2hex(cell_rgb(main, r, c)) != given[n]]
    rep.add('заданные hex 10–13', F, 'FAIL' if bad else 'OK', ' '.join(bad))
    ctrl = {'sand_00': '#7A5A3A', 'sand_08': '#BD9D72', 'sand_15': '#F2DFB4'}
    got = {n: cell_rgb(main, 1, int(n[-2:])) for n in ctrl}
    ok = all(abs(a - b) <= 1 for n in ctrl for a, b in zip(got[n], hex2rgb(ctrl[n])))
    rep.add('контроль sand', F, 'OK' if ok else 'FAIL', ' '.join(f'{n}={rgb2hex(v)}' for n, v in got.items()))
    gbad = []
    for s, (name, frm, to) in enumerate(GRADS):
        strip = main[448:, s * 64:(s + 1) * 64]
        if not (strip == strip[:, :1]).all():
            gbad.append(f'{name}:не ровно по ширине')
        labs = [rgb2lab([int(v) for v in strip[y, 0]]) for y in range(64)]
        e0, e1 = dE(labs[0], hex2lab(frm)), dE(labs[-1], hex2lab(to))
        A, B = hex2lab(frm), hex2lab(to)
        D = [B[q] - A[q] for q in range(3)]
        proj = [sum((l[q] - A[q]) * D[q] for q in range(3)) for l in labs]
        if e0 > 0.01 or e1 > 0.01:
            gbad.append(f'{name}:from {e0:.4f} to {e1:.4f}')
        if any(proj[y + 1] < proj[y] - 1e-9 for y in range(63)):
            gbad.append(f'{name}:не монотонно')
    rep.add('градиенты from/to, монотонность', F, 'FAIL' if gbad else 'OK', ' '.join(gbad))
    E = pal['entries']
    nm = [e['name'] for e in E]
    expected = [n for row in names for n in row] + [g[0] for g in GRADS]
    inside = all(
        e['uv_safe_rect'][0] > e['px_rect'][0] / 512 and e['uv_safe_rect'][2] < (e['px_rect'][0] + e['px_rect'][2]) / 512
        and e['uv_safe_rect'][1] > 1 - (e['px_rect'][1] + e['px_rect'][3]) / 512 and e['uv_safe_rect'][3] < 1 - e['px_rect'][1] / 512
        for e in E)
    ok = len(E) == 232 and len(set(nm)) == 232 and nm == expected and inside
    rep.add('palette.json', 'palette.json', 'OK' if ok else 'FAIL', f'{len(E)} записей, {len(set(nm))} уникальных')
    ref = tools_dir / 'legacy_js' / '_cells.json'
    if ref.exists():
        js = [[(c['name'], c['hex']) for c in row] for row in json.loads(ref.read_text())['cells']]
        diff = [f'{a[0]}:{a[1]}≠{b[1]}' for ra, rb in zip(cells, js) for a, b in zip(ra, rb) if a != b]
        rep.add('совпадение с _cells.json (JS)', 'palette.json', 'FAIL' if diff else 'OK', ' '.join(diff))

    changed = {'T_Palette_Worn': [r for r in range(16) if r != 10], 'T_Palette_WeaponSkin_Gold': [12],
               'T_Palette_WeaponSkin_Arctic': [12], 'T_Palette_Armor_State2': [13], 'T_Palette_Armor_State3': [13]}
    for v, rows in changed.items():
        mask = np.ones(512, bool)
        for r in rows:
            mask[r * CELL:(r + 1) * CELL] = False
        same = (variants[v][mask] == main[mask]).all()
        rep.add('прочие строки побайтово равны', v + '.png', 'OK' if same else 'FAIL')
    for v in ('T_Palette_Worn', 'T_Palette_Armor_State2'):
        check_uniform(rep, variants[v], v + '.png')
        rows = [r for r in changed[v] if r < 14]
        check_distinct(rep, variants[v], v + '.png', rows, 0.02, 0.02, names)
    for v, cols in VARIANTS.items():
        im = variants[v]
        hexbad = [str(c) for c, h in cols[12].items() if rgb2hex(cell_rgb(im, 12, c)) != h]
        bad, mn = [], 9.0
        for g in WEAPON_SKIN_GROUPS:
            for i in range(len(g) - 1):
                e = dE(rgb2lab(cell_rgb(im, 12, g[i])), rgb2lab(cell_rgb(im, 12, g[i + 1])))
                mn = min(mn, e)
                if e < 0.02:
                    bad.append(f'{g[i]}/{g[i + 1]}:{e:.4f}')
        rep.add('различимость строка 12 (группы)', v + '.png', 'FAIL' if bad or hexbad else 'OK',
                f'min {mn:.4f} ' + ' '.join(bad) + (' hex≠ ' + ','.join(hexbad) if hexbad else ''))
    im = variants['T_Palette_Armor_State3']
    warn = []
    for a in range(16):
        for b in range(a + 1, 16):
            e = dE(rgb2lab(cell_rgb(im, 13, a)), rgb2lab(cell_rgb(im, 13, b)))
            if e < 0.02:
                warn.append(f'{names[13][a]}/{names[13][b]}:{e:.4f}')
    rep.add('пары ΔE<0.02 (намеренно)', 'T_Palette_Armor_State3.png', 'WARN' if warn else 'OK', ' '.join(warn))

    sizes = {'T_VehicleSkin_Test': (1024, 1024, 4), 'T_Sticker_Flames_01': (512, 512, 4),
             'T_Plate_01': (128, 256, 3), 'T_Glass_Cracked_01': (512, 512, 4)}
    for name, (im_, ch) in samples.items():
        arr = im_.d if ch == 4 else im_.d[..., :3]
        detail = f'{arr.shape[1]}×{arr.shape[0]} {"RGBA" if ch == 4 else "RGB"}'
        st = 'OK' if arr.shape == sizes[name] else 'FAIL'
        if ch == 4:
            halo = halo_check(arr)
            detail += f' ореол max ΔE {halo:.4f}'
            if halo > 0.05:
                st = 'FAIL'
        rep.add('размер/режим/ореол', name + '.png', st, detail)
    return rep


# ---------- Сборка ----------

def write(path_, data):
    path_.parent.mkdir(parents=True, exist_ok=True)
    path_.write_bytes(data)


def main():
    tools_dir = Path(__file__).resolve().parent
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', type=Path, default=tools_dir.parent, help='папка assets (по умолчанию — рядом с tools)')
    out = ap.parse_args().out.resolve()
    tex = out / 'textures' / 'models'

    cells = build_cells()
    main_im = render_palette(cells)
    variants = build_variants(main_im)
    pal = palette_json(cells)
    C = {n: hex2rgb(h) for row in cells for n, h in row}
    samples = build_samples(C)

    images = {'T_Palette_Main': main_im}
    order = ['T_Palette_Worn', 'T_Palette_WeaponSkin_Gold', 'T_Palette_WeaponSkin_Arctic',
             'T_Palette_Armor_State2', 'T_Palette_Armor_State3']
    images.update((k, variants[k]) for k in order)
    images.update((k, im.d if ch == 4 else im.d[..., :3]) for k, (im, ch) in samples.items())

    sha = {}
    for name, arr in images.items():
        data = png_bytes(np.ascontiguousarray(arr))
        write(tex / f'{name}.png', data)
        sha[f'{name}.png'] = hashlib.sha256(data).hexdigest()
    data = png_bytes(build_preview(images))
    write(tex / '_preview.png', data)
    sha['_preview.png'] = hashlib.sha256(data).hexdigest()
    data = json.dumps(pal, indent=1, ensure_ascii=False).encode()
    write(out / 'palette' / 'palette.json', data)
    sha['assets/palette/palette.json'] = hashlib.sha256(data).hexdigest()
    for rel, data in gen_test_mesh.build(pal).items():
        write(out / rel, data)
        if rel.endswith('.obj'):
            sha[f'assets/{rel}'] = hashlib.sha256(data).hexdigest()

    rep = selfcheck(main_im, variants, pal, cells, samples, tools_dir)
    write(tex / '_selfcheck_palette.txt', ('\n'.join(rep.lines) + '\n').encode())

    info = {
        'generator': 'Python (assets/tools/gen_palette.py, gen_test_mesh.py)',
        'python': sys.version.split()[0],
        'pillow': PIL.__version__,
        'numpy': np.__version__,
        'SEED': SEED,
        'sha256': sha,
    }
    write(tex / '_build_info.json', json.dumps(info, indent=1, ensure_ascii=False).encode())

    print('\n'.join(rep.lines))
    print(f'\nFAIL: {rep.fails}. Выход: {out}')
    return 1 if rep.fails else 0


if __name__ == '__main__':
    sys.exit(main())
