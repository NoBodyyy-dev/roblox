"""Двор лобби: перевалочный пункт выживших посреди заброшенного города.

Двор 96×80 studs, ворота на северной стене (+Y Blender): Море x=−30, Город x=0, Горы x=+30.
Игроки появляются у южной стены и идут к воротам мимо костра.
"""
import math
import random

import bmesh
from mathutils import Matrix, Vector

import build_style_test as bst

HX, HY, WALL_T = 48.0, 40.0, 1.0
GATES = {'Sea': -30.0, 'City': 0.0, 'Mountains': 30.0}
GAP = 7.6  # полупроём под ворота (стойки на ±6.6)


def ground(rng):
    p = bst.Part('Ground')
    p.box((0, 0, -0.5), (HX * 2 + 8, HY * 2 + 8, 1.0), by_top('asphalt_08', 'asphalt_05'))
    for _ in range(18):  # грязь и пыль
        c = Vector((rng.uniform(-HX + 4, HX - 4), rng.uniform(-HY + 4, HY - 4)))
        flat(p, bst.blob(c, rng.uniform(4, 10), rng.uniform(3, 7), rng), rng.choice(('sand_07', 'sand_05', 'asphalt_10', 'asphalt_06')), 0.02)
    for _ in range(5):  # лужи
        c = Vector((rng.uniform(-HX + 6, HX - 6), rng.uniform(-HY + 6, HY - 10)))
        flat(p, bst.blob(c, rng.uniform(3, 6), rng.uniform(2, 4), rng), 'water_04', 0.03)
    for _ in range(14):  # трещины
        a = Vector((rng.uniform(-HX, HX), rng.uniform(-HY, HY)))
        d = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1))).normalized()
        for _k in range(3):
            b = a + d * rng.uniform(2, 5)
            n = Vector((-d.y, d.x)) * 0.12
            flat(p, [a - n, b - n * 0.3, b + n * 0.3, a + n], 'asphalt_04', 0.035)
            a, d = b, (d + Vector((rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6)))).normalized()
    # разметка мест под магазин и лидерборды (сами стенды — P5): жёлтые рамки
    for c, s in [((38, 4), (14, 18))] + [((x, -32), (12, 8)) for x in (-34, -20, -6)]:
        outline(p, c, s, 'signal_yellow_dark')
    return p


def by_top(top, side):
    return bst.by_normal(top, side)


def flat(p, pts2d, cell, z):
    pts = [Vector((v.x, v.y, z)) for v in pts2d]
    c = sum(pts, Vector()) / len(pts)
    p.poly(pts, cell, c - Vector((0, 0, 1)))


def outline(p, c, s, cell, w=0.35):
    cx, cy = c
    sx, sy = s
    for dx, dy, ex, ey in ((0, sy / 2, sx, w), (0, -sy / 2, sx, w), (sx / 2, 0, w, sy), (-sx / 2, 0, w, sy)):
        flat(p, [Vector((cx + dx - ex / 2, cy + dy - ey / 2)), Vector((cx + dx + ex / 2, cy + dy - ey / 2)),
                 Vector((cx + dx + ex / 2, cy + dy + ey / 2)), Vector((cx + dx - ex / 2, cy + dy + ey / 2))], cell, 0.04)


def walls(rng, colliders):
    """Сборное ограждение: бетонные блоки, профлист, мешки с песком, доски — чередуются по 8 studs."""
    p = bst.Part('Walls')
    runs = []  # (a0, a1, fixed, axis)
    xs = sorted([-HX, HX] + [g - GAP for g in GATES.values()] + [g + GAP for g in GATES.values()])
    for a0, a1 in zip(xs[0::2], xs[1::2]):
        runs.append((a0, a1, HY, 'x'))
    runs += [(-HX, HX, -HY, 'x'), (-HY, HY, HX, 'y'), (-HY, HY, -HX, 'y')]
    kinds = ('blocks', 'sheet', 'bags', 'boards')
    for a0, a1, fixed, axis in runs:
        a = a0
        while a < a1 - 0.1:
            b = min(a + 8.0, a1)
            seg(p, rng.choice(kinds), a, b, fixed, axis, rng)
            m = (a + b) / 2
            c = (m, fixed, 4.5) if axis == 'x' else (fixed, m, 4.5)
            s = (b - a, WALL_T * 1.6, 9.0) if axis == 'x' else (WALL_T * 1.6, b - a, 9.0)
            colliders.append((Vector(c), Vector(s), None))
            a = b
    return p


def seg(p, kind, a, b, fixed, axis, rng):
    def put(along, z, size, cell, off=0.0, rot=None):
        c = (along, fixed + off, z) if axis == 'x' else (fixed + off, along, z)
        s = size if axis == 'x' else (size[1], size[0], size[2])
        p.box(c, s, cell, rot)

    m, L = (a + b) / 2, b - a
    if kind == 'blocks':
        put(m, 1.0, (L, 1.6, 2.0), 'asphalt_09')
        put(m + rng.uniform(-0.5, 0.5), 3.0, (L - 1.0, 1.4, 2.0), 'asphalt_10')
        put(m, 5.6, (L, 0.3, 3.2), 'rust_07')  # лист поверх блоков
    elif kind == 'sheet':
        h = rng.uniform(7.5, 9.0)
        for x in (a + 0.3, b - 0.3):
            put(x, h / 2, (0.4, 0.4, h), 'wood_04')
        for i in range(4):
            put(a + L * (i + 0.5) / 4, h / 2, (L / 4, 0.25, h - 0.4), ('rust_06', 'metal_05', 'rust_09', 'metal_06')[i])
    elif kind == 'bags':
        for row in range(4):
            put(m + (0.5 if row % 2 else -0.5), 0.5 + row * 0.95, (L - 0.6, 1.8 - row * 0.15, 1.0),
                ('khaki', 'khaki_dark', 'khaki_light')[row % 3])
        put(m, 5.8, (L, 0.2, 3.6), 'wood_06')
    else:  # boards
        h = rng.uniform(7.0, 8.5)
        for x in (a + 0.3, b - 0.3):
            put(x, h / 2, (0.5, 0.5, h), 'wood_03')
        for i in range(6):
            put(m + rng.uniform(-0.3, 0.3), 0.8 + i * (h - 1) / 6, (L - 0.2, 0.2, (h - 1) / 6 - 0.15),
                ('wood_07', 'wood_09', 'wood_06')[i % 3], 0.0, bst.R('Y' if axis == 'x' else 'X', rng.uniform(-3, 3)))


def stone(p, c, r, rng, cell):
    tmp = bmesh.new()
    bmesh.ops.create_icosphere(tmp, subdivisions=1, radius=1.0)
    vs = {}
    for v in tmp.verts:
        k = 1 + rng.uniform(-0.25, 0.25)
        vs[v] = p.bm.verts.new(Vector(c) + Vector((v.co.x * r * k, v.co.y * r * k, max(v.co.z, -0.3) * r * 0.7 * k)))
    for f in tmp.faces:
        nf = p.bm.faces.new([vs[v] for v in f.verts])
        bst.orient(nf, Vector(c), True)
        p.pending.append((nf, cell))
    tmp.free()


def props(rng, colliders, att):
    p = bst.Part('Props')
    fire = bst.Part('Fire')
    # костёр в центре: кольцо камней, поленья, огонь
    fc = Vector((0, -4, 0))
    for i in range(10):
        a = 2 * math.pi * i / 10
        stone(p, fc + Vector((math.cos(a) * 2.2, math.sin(a) * 2.2, 0.25)), 0.55, rng, rng.choice(('asphalt_07', 'asphalt_09')))
    for k in range(4):
        p.cyl(fc + Vector((0, 0, 0.45)), 0.25, 3.0, 6, 'wood_02', 'X')
        p.bm.verts.ensure_lookup_table()
        rot = Matrix.Rotation(math.radians(45 * k + 10), 4, 'Z') @ Matrix.Rotation(math.radians(18), 4, 'Y')
        for v in p.bm.verts[-12:]:
            v.co = fc + rot.to_3x3() @ (v.co - fc) + Vector((0, 0, 0.3))
    for h, r, cell, rz in ((3.6, 1.3, 'signal_red_base', 0), (3.0, 1.0, 'signal_orange_base', 40),
                           (2.2, 0.7, 'signal_yellow_base', 80), (1.6, 0.6, 'signal_orange_light', 130)):
        # языки пламени разведены по кругу и наклонены наружу, чтобы были видны все цвета
        off = Matrix.Rotation(math.radians(rz * 2.2), 3, 'Z') @ Vector((0.0 if cell == 'signal_red_base' else 0.7, 0, 0))
        r *= 0.7
        fc2 = fc + off
        base = [fc2 + Matrix.Rotation(math.radians(rz + 90 * i), 3, 'Z') @ Vector((r, 0, 0.6)) for i in range(4)]
        fire.solid(base + [fc2 + off * 0.6 + Vector((0, 0, 0.6 + h))],
                   [(0, 1, 2, 3), (0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4)], cell, fc2 + Vector((0, 0, 1.2)))
    att['Campfire'] = fc + Vector((0, 0, 1.2))
    colliders.append((fc + Vector((0, 0, 0.6)), Vector((5.5, 5.5, 1.2)), None))
    # сиденья у костра: брёвна и лавки
    for i, a in enumerate((200, 250, 290, 340, 30)):
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0))
        c = fc + d * 6.0
        if i % 2:
            p.box(c + Vector((0, 0, 1.0)), (3.6, 0.9, 0.25), 'wood_09', Matrix.Rotation(math.radians(a + 90), 4, 'Z'))
            for s in (-1.3, 1.3):
                p.box(c + Matrix.Rotation(math.radians(a + 90), 3, 'Z') @ Vector((s, 0, 0.45)), (0.9, 0.9, 0.9), 'wood_06')
        else:
            p.cyl(Vector((0, 0, 0)), 0.55, 3.8, 7, 'wood_04', 'X')
            p.bm.verts.ensure_lookup_table()
            rot = Matrix.Rotation(math.radians(a + 90), 3, 'Z')
            for v in p.bm.verts[-14:]:
                v.co = c + rot @ v.co + Vector((0, 0, 0.55))
    # гирлянда над костром: 4 столба, провода, лампочки
    poles = [fc + Vector((sx * 9, sy * 8, 0)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    for q in poles:
        p.box(q + Vector((0, 0, 4.5)), (0.4, 0.4, 9.0), 'wood_03')
    for q0, q1 in zip(poles, poles[1:] + poles[:1]):
        mid = (q0 + q1) / 2 + Vector((0, 0, 7.8))
        for t0, t1 in ((q0 + Vector((0, 0, 8.6)), mid), (mid, q1 + Vector((0, 0, 8.6)))):
            d = t1 - t0
            p.box((t0 + t1) / 2, (d.length, 0.06, 0.06), 'neutral_02',
                  Matrix.Rotation(math.atan2(d.y, d.x), 4, 'Z') @ Matrix.Rotation(-math.atan2(d.z, d.xy.length), 4, 'Y'))
            for k in (0.25, 0.75):
                p.box(t0 + d * k - Vector((0, 0, 0.25)), (0.3, 0.3, 0.4), 'signal_yellow_lighter')
    # палатки (запад)
    for c, rz in (((-36, 10), 80), ((-36, -6), 100), ((-26, 24), 30)):
        c = Vector((c[0], c[1], 0))
        rot = Matrix.Rotation(math.radians(rz), 3, 'Z')
        tri = [c + rot @ Vector((-3.0, -2.6, 0)), c + rot @ Vector((3.0, -2.6, 0)), c + rot @ Vector((0, -2.6, 4.2))]
        p.prism(tri, rot @ Vector((0, 5.2, 0)), bst.by_normal('cloth', 'cloth_dark', k=0.3))
        p.box(c + rot @ Vector((0, -2.62, 1.3)), (1.6, 0.05, 2.4), 'neutral_02',
              Matrix.Rotation(math.radians(rz), 4, 'Z'))  # вход
        colliders.append((c + Vector((0, 0, 2.0)), Vector((6.0, 6.0, 4.0)), Matrix.Rotation(math.radians(rz), 4, 'Z')))
    # ящики, бочки, поддоны, генератор (восток и углы)
    for _ in range(26):
        c = Vector((rng.choice((rng.uniform(26, 44), rng.uniform(-44, -28))), rng.uniform(-34, 34), 0))
        if abs(c.y + 32) < 6 or (abs(c.x - 38) < 8 and abs(c.y - 4) < 10):
            continue  # не занимать разметку магазина и лидербордов
        kind = rng.random()
        if kind < 0.45:
            s = rng.uniform(1.6, 2.4)
            p.box(c + Vector((0, 0, s / 2)), (s, s, s), rng.choice(('wood_07', 'wood_09', 'khaki')), bst.R('Z', rng.uniform(0, 90)))
            if rng.random() < 0.5:
                p.box(c + Vector((0, 0, s + s * 0.4)), (s * 0.8, s * 0.8, s * 0.8), 'wood_08', bst.R('Z', rng.uniform(0, 90)))
        elif kind < 0.8:
            for k in range(rng.randint(1, 3)):
                p.cyl(c + Vector((k * 1.3, 0, 1.1)), 0.65, 2.2, 8, rng.choice(('rust_08', 'metal_06', 'faded_blue_1', 'faded_red_1')), 'Z')
        else:
            p.box(c + Vector((0, 0, 0.15)), (2.4, 2.4, 0.3), 'wood_06')
        colliders.append((c + Vector((0.6, 0, 1.2)), Vector((3.0, 3.0, 2.4)), None))
    gen = Vector((24, 30, 0))
    p.box(gen + Vector((0, 0, 1.2)), (3.0, 2.0, 2.0), 'faded_yellow_0')
    p.box(gen + Vector((0, 0, 2.3)), (3.2, 2.2, 0.25), 'metal_03')
    p.cyl(gen + Vector((1.0, 0, 2.9)), 0.15, 1.2, 6, 'metal_02', 'Z')
    colliders.append((gen + Vector((0, 0, 1.2)), Vector((3.2, 2.2, 2.4)), None))
    # навес из брезента у северной стены (между воротами Города и Гор): столбы, скат, стол с припасами
    cv = Vector((15, 33, 0))
    for sx in (-1, 1):
        for sy, h in ((-1, 6.0), (1, 7.5)):
            p.box(cv + Vector((sx * 5, sy * 3, h / 2)), (0.4, 0.4, h), 'wood_03')
    p.box(cv + Vector((0, 0, 6.85)), (11.0, 7.0, 0.15), bst.by_normal('khaki', 'khaki_dark'), bst.R('X', -12))
    p.box(cv + Vector((0, 0.5, 1.0)), (6.0, 2.0, 0.25), 'wood_08')  # стол
    for sx in (-2.6, 2.6):
        p.box(cv + Vector((sx, 0.5, 0.45)), (0.3, 1.8, 0.9), 'wood_05')
    for k, cell in enumerate(('faded_red_1', 'neutral_13', 'faded_blue_1', 'khaki', 'faded_yellow_1')):
        p.box(cv + Vector((-2.4 + k * 1.2, 0.5, 1.45)), (0.8, 0.8, 0.7), cell)  # канистры, коробки, аптечка
    colliders.append((cv + Vector((0, 0.5, 0.6)), Vector((6.0, 2.0, 1.2)), None))
    # мешки с песком подковой у подножия вышки
    for i in range(7):
        a = math.radians(180 + i * 15)
        q = Vector((40, 32, 0)) + Vector((math.cos(a), math.sin(a), 0)) * 5.5
        p.box(q + Vector((0, 0, 0.5)), (1.6, 0.9, 1.0), ('khaki', 'khaki_dark')[i % 2], bst.R('Z', math.degrees(a) + 90))
    # доска объявлений у ворот города
    nb = Vector((12, 30, 0))
    for x in (-1.6, 1.6):
        p.box(nb + Vector((x, 0, 2.2)), (0.3, 0.3, 4.4), 'wood_03')
    p.box(nb + Vector((0, 0, 3.0)), (4.0, 0.25, 2.4), 'wood_06')
    for _ in range(6):
        p.box(nb + Vector((rng.uniform(-1.5, 1.5), -0.16, rng.uniform(2.1, 3.9))), (0.6, 0.04, 0.8),
              rng.choice(('armor_paper_white', 'armor_paper_aged', 'armor_paper_cream')), bst.R('Y', rng.uniform(-12, 12)))
    return p, fire


def tower(colliders, att):
    """Сторожевая вышка в северо-восточном углу — ориентир лобби."""
    p = bst.Part('Tower')
    c, top = Vector((40, 32, 0)), 16.0
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.box(c + Vector((sx * 2.2, sy * 2.2, top / 2)), (0.6, 0.6, top), 'wood_03', bst.R('X', -sy * 3) @ bst.R('Y', sx * 3))
    for z in (5.0, 10.5):
        for sx in (-1, 1):
            p.box(c + Vector((sx * 2.2, 0, z)), (0.3, 4.4, 0.3), 'wood_05')
            p.box(c + Vector((0, sx * 2.2, z)), (4.4, 0.3, 0.3), 'wood_05')
    p.box(c + Vector((0, 0, top)), (6.0, 6.0, 0.4), 'wood_07')  # площадка
    for sx in (-1, 1):
        p.box(c + Vector((sx * 2.9, 0, top + 1.0)), (0.2, 6.0, 1.6), 'wood_08')
        p.box(c + Vector((0, sx * 2.9, top + 1.0)), (6.0, 0.2, 1.6), 'wood_08')
    for sx in (-1, 1):
        for sy in (-1, 1):
            p.box(c + Vector((sx * 2.8, sy * 2.8, top + 2.4)), (0.25, 0.25, 4.8), 'wood_04')
    p.box(c + Vector((0, 0, top + 4.9)), (7.0, 7.0, 0.3), 'rust_06', bst.R('Y', 8))  # навес из профлиста
    for k in range(12):  # лестница
        p.box(c + Vector((-1.2, -2.9, 0.8 + k * 1.3)), (1.6, 0.2, 0.2), 'wood_06')
    for x in (-2.0, -0.4):
        p.box(c + Vector((x, -2.9, top / 2)), (0.2, 0.2, top), 'wood_04')
    colliders.append((c + Vector((0, 0, top / 2)), Vector((5.0, 5.0, top)), None))
    colliders.append((c + Vector((0, 0, top + 0.2)), Vector((6.0, 6.0, 0.4)), None))
    att['Lookout'] = c + Vector((0, 0, top + 0.2))
    return p


def backdrop(rng):
    """Заброшенный город за оградой: силуэты домов с тёмными окнами, без коллизии."""
    p = bst.Part('Backdrop')
    spots = [((-40, 62), (22, 14), 34), ((-12, 66), (18, 16), 46), ((16, 60), (20, 14), 28), ((42, 68), (16, 16), 52),
             ((72, 20), (14, 24), 38), ((70, -18), (14, 20), 24), ((-72, 14), (14, 22), 30), ((-70, -24), (14, 18), 40)]
    for (x, y), (w, d), h in spots:
        c = Vector((x, y, 0))
        p.box(c + Vector((0, 0, h / 2)), (w, d, h), bst.by_normal('asphalt_05', rng.choice(('sand_06', 'asphalt_07', 'terracotta_06'))))
        if rng.random() < 0.6:  # обрушенный угол
            p.box(c + Vector((w * 0.3, 0, h + 1.5)), (w * 0.4, d * 0.8, 3.0), 'asphalt_06', bst.R('Y', 12))
        face_y = c.y - d / 2 - 0.02 if abs(x) < 60 else None
        floors, cols = int(h // 10), max(2, int(w // 5))
        for fl in range(floors):
            for k in range(cols):
                if rng.random() < 0.15:
                    continue
                if face_y is not None:
                    wx = x - w / 2 + (k + 0.5) * w / cols
                    p.box(Vector((wx, face_y, 5 + fl * 10)), (2.0, 0.05, 3.2), 'neutral_01')
                else:
                    fx = x - w / 2 - 0.02 if x > 0 else x + w / 2 + 0.02
                    wy = y - d / 2 + (k + 0.5) * d / cols
                    p.box(Vector((fx, wy, 5 + fl * 10)), (0.05, 2.0, 3.2), 'neutral_01')
    return p


def hub():
    rng = random.Random(11)
    colliders, att = [], {}
    g = ground(rng)
    w = walls(rng, colliders)
    pr, fire = props(rng, colliders, att)
    tw = tower(colliders, att)
    colliders.append((Vector((0, 0, -0.5)), Vector((HX * 2 + 8, HY * 2 + 8, 1.0)), None))
    for i, x in enumerate((-12, -4, 4, 12), 1):
        att[f'Spawn_{i}'] = Vector((x, -30, 0))
    for region, x in GATES.items():
        att[f'DoorSlot_{region}'] = Vector((x, HY, 0))
    att['Shop'] = Vector((38, 4, 0))
    for i, x in enumerate((-34, -20, -6), 1):
        att[f'Leaderboard_{i}'] = Vector((x, -32, 0))
    return {
        'name': 'Lobby_Hub', 'category': 'Lobby', 'primary': 'Ground', 'parts': [g, w, pr, fire, tw],
        'pivots': {}, 'attachments': {k: ('Ground', v) for k, v in att.items()}, 'colliders': colliders,
        'attributes': {}, 'studio': {
            'Ground': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False},  # пол — картинка, ходят по коллайдеру-боксу
            'Walls': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False},
            'Props': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False},
            'Fire': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False, 'Material': 'Neon'},
            'Tower': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False},
        },
    }
