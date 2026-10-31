"""Фон лобби: мрачные разрушенные дома вокруг двора (отдельная модель Lobby_Backdrop, без коллизии).

Ближний ряд — дома с деталями на фасаде, обращённом во двор: карнизы, балконы, пожарные лестницы,
тёмные / выбитые / заколоченные окна, копоть, баки и антенны, обрушенные углы с завалами.
Дальний ряд — тёмные силуэты для глубины. Pivot модели совпадает с центром двора (как у Lobby_Hub).
"""
import math
import random

from mathutils import Vector

import build_style_test as bst
import lobby_hub

WALLS = ('asphalt_05', 'asphalt_06', 'neutral_05', 'sand_03', 'terracotta_03', 'rust_03', 'neutral_06')
ZF = 10.0  # высота этажа


class Facade:
    def __init__(self, c, n, w, d, h):
        self.c, self.n, self.w, self.d, self.h = Vector(c), Vector(n), w, d, h
        self.t = Vector((-n[1], n[0], 0))
        self.face = self.c + self.n * (d / 2)

    def at(self, a, z, off=0.0):
        return self.face + self.t * a + self.n * off + Vector((0, 0, z))

    def size(self, along, out, up):
        """Размер бокса в осях мира: along — по фасаду, out — по нормали."""
        return (along, out, up) if abs(self.t.x) > 0.5 else (out, along, up)


def building(p, c, n, w, d, h, rng):
    f = Facade(c, n, w, d, h)
    wall = rng.choice(WALLS)
    p.box(f.c + Vector((0, 0, h / 2)), f.size(w, d, h), bst.by_normal('asphalt_03', wall))
    floors, cols = int(h // ZF), max(2, int(w // 5.5))
    collapsed = rng.random() < 0.55
    cut_a = w / 2 * rng.choice((-1, 1))
    for fl in range(floors):
        z = fl * ZF
        if fl:  # межэтажный карниз
            p.box(f.at(0, z, 0.25), f.size(w + 0.4, 0.5, 0.5), 'asphalt_07')
        for k in range(cols):
            a = -w / 2 + (k + 0.5) * w / cols
            if collapsed and fl >= floors - 2 and abs(a - cut_a) < w * 0.3:
                continue  # окна в обрушенном углу не нужны
            zc = z + 5.2
            r = rng.random()
            if r < 0.12:  # заколочено
                p.box(f.at(a, zc, 0.06), f.size(2.2, 0.1, 3.4), 'neutral_02')
                for j in range(3):
                    p.box(f.at(a, zc - 1.0 + j * 1.0, 0.18), f.size(2.8, 0.15, 0.45), rng.choice(('wood_03', 'wood_05')),
                          bst.R('X' if abs(f.t.x) < 0.5 else 'Y', rng.uniform(-10, 10)))
            elif r < 0.16:  # тусклый свет — кто-то живёт
                p.box(f.at(a, zc, 0.04), f.size(2.2, 0.08, 3.4), 'signal_orange_dark')
            else:
                p.box(f.at(a, zc, 0.04), f.size(2.2, 0.08, 3.4), 'neutral_01')
                if r > 0.8:  # осколки стекла по краю
                    p.box(f.at(a - 0.7, zc + 1.1, 0.1), f.size(0.6, 0.05, 1.0), 'water_02', bst.R('X' if abs(f.t.x) < 0.5 else 'Y', 20))
                p.box(f.at(a, z + 3.3, 0.2), f.size(2.6, 0.4, 0.25), 'asphalt_08')  # подоконник
            if rng.random() < 0.3:  # копоть над окном
                top = f.at(a, zc + 1.7, 0.09)
                hh = rng.uniform(1.0, 2.2)  # широкое размытое пятно, а не острый «колпак»
                pts = [top + f.t * -1.1, top + f.t * 1.1, top + f.t * 0.8 + Vector((0, 0, hh)),
                       top + f.t * 0.1 + Vector((0, 0, hh * 1.3)), top + f.t * -0.8 + Vector((0, 0, hh * 0.9))]
                p.poly(pts, 'asphalt_03', top - f.n)
        if 0 < fl < floors - 1 and rng.random() < 0.35:  # балкон
            a = -w / 2 + (rng.randrange(cols) + 0.5) * w / cols
            p.box(f.at(a, z + 0.2, 1.1), f.size(3.4, 2.2, 0.35), 'asphalt_07')
            p.box(f.at(a, z + 1.2, 2.15), f.size(3.4, 0.12, 1.6), 'metal_02')
    if rng.random() < 0.5 and floors > 2:  # пожарная лестница
        a0 = rng.choice((-1, 1)) * w * 0.32
        for fl in range(1, floors):
            z = fl * ZF
            p.box(f.at(a0, z, 1.0), f.size(4.0, 1.8, 0.2), 'metal_02')
            p.box(f.at(a0 + (1.2 if fl % 2 else -1.2), z - ZF / 2, 1.0), f.size(0.8, 1.2, ZF * 1.05), 'metal_01',
                  bst.R('X' if abs(f.t.x) < 0.5 else 'Y', 0))
            p.box(f.at(a0, z + 0.9, 1.85), f.size(4.0, 0.08, 0.9), 'metal_03')
    if collapsed:  # обрушенный угол: рваный верх, плиты перекрытий, завал у подножия
        for s in range(3):
            hh = rng.uniform(2, 6)
            p.box(f.at(cut_a * (0.55 + 0.15 * s), h - ZF * 1.4 + hh / 2, -d / 2), f.size(w * 0.28, d * 1.02, hh),
                  'asphalt_04', bst.R('Z', rng.uniform(-4, 4)))
        for s in range(2):
            p.box(f.at(cut_a * 0.75, h - ZF * (1.6 + s), 0.6), f.size(w * 0.3, 1.6, 0.4), 'asphalt_08', bst.R('Y', rng.uniform(-14, 14)))
        for _ in range(6):
            q = f.at(cut_a * rng.uniform(0.4, 1.0), 0, rng.uniform(1, 5))
            s = rng.uniform(1.2, 3.0)
            p.box(q + Vector((0, 0, s / 3)), (s, s * 0.8, s * 0.6), rng.choice(('asphalt_06', 'asphalt_09', wall)), bst.rnd_rot(rng, 25))
    else:  # крыша: парапет, бак, антенна, короба
        p.box(f.c + Vector((0, 0, h + 0.6)), f.size(w, d, 1.2), bst.by_normal('asphalt_02', 'asphalt_06'))
        if rng.random() < 0.6:
            q = f.c + f.t * rng.uniform(-w / 4, w / 4) + Vector((0, 0, h + 1.2))
            for sx in (-1, 1):
                p.box(q + Vector((sx * 1.2, 0, 1.5)), (0.3, 0.3, 3.0), 'metal_02')
            p.cyl(q + Vector((0, 0, 4.4)), 1.8, 3.2, 8, 'rust_04', 'Z')
        if rng.random() < 0.6:
            q = f.c + f.t * rng.uniform(-w / 3, w / 3) + Vector((0, 0, h + 1.2))
            p.box(q + Vector((0, 0, 4.0)), (0.25, 0.25, 8.0), 'metal_03')
            p.box(q + Vector((0, 0, 6.5)), (2.4, 0.12, 0.12), 'metal_03')
        for _ in range(rng.randint(1, 3)):
            q = f.c + f.t * rng.uniform(-w / 3, w / 3) + f.n * rng.uniform(-d / 4, d / 4) + Vector((0, 0, h + 1.2))
            p.box(q + Vector((0, 0, 0.7)), (2.0, 1.6, 1.4), 'metal_04')
    for _ in range(3):  # мусор у фасада
        q = f.at(rng.uniform(-w / 2, w / 2), 0, rng.uniform(0.5, 3))
        p.box(q + Vector((0, 0, 0.4)), (1.4, 1.0, 0.8), rng.choice(('asphalt_06', 'rust_05', 'wood_03')), bst.rnd_rot(rng, 15))


def backdrop():
    rng = random.Random(23)
    p = bst.Part('Buildings')
    far = bst.Part('Skyline')
    HX, HY = lobby_hub.HX, lobby_hub.HY
    near = [  # (центр x, y), нормаль фасада во двор, ширина по фасаду, глубина, высота
        ((-42, HY + 20), (0, -1), 24, 14, 34), ((-14, HY + 22), (0, -1), 20, 16, 52), ((14, HY + 19), (0, -1), 22, 12, 28),
        ((44, HY + 24), (0, -1), 18, 16, 44),
        ((HX + 20, 22), (-1, 0), 26, 14, 40), ((HX + 18, -14), (-1, 0), 22, 12, 24),
        ((-HX - 20, 16), (1, 0), 24, 14, 32), ((-HX - 19, -22), (1, 0), 20, 12, 46),
        ((0, -HY - 20), (0, 1), 30, 12, 22),
    ]
    for c, n, w, d, h in near:
        building(p, (c[0], c[1], 0), (n[0], n[1], 0), w, d, h, rng)
    for _ in range(14):  # дальний ряд силуэтов
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(120, 170)
        c = Vector((math.cos(a) * r, math.sin(a) * r * 0.9, 0))
        w, h = rng.uniform(14, 26), rng.uniform(30, 75)
        far.box(c + Vector((0, 0, h / 2)), (w, w * 0.8, h), bst.by_normal('asphalt_01', rng.choice(('asphalt_02', 'asphalt_03', 'neutral_03'))))
        if rng.random() < 0.5:
            far.box(c + Vector((w * 0.25, 0, h + 3)), (w * 0.4, w * 0.6, 6), 'asphalt_02', bst.R('Y', rng.uniform(-15, 15)))
    return {
        'name': 'Lobby_Backdrop', 'category': 'Lobby', 'primary': 'Buildings', 'parts': [p, far],
        'pivots': {}, 'attachments': {}, 'colliders': [], 'attributes': {},
        'studio': {'*': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False, 'CastShadow': False}},
    }
