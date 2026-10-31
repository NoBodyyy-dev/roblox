"""Ворота лобби (ASSETS_PROMPT §6 «Дверь лобби»): Door (pivot на петле), Sign, Lock, Frame; Attachment Entrance.

Локальные координаты ворот: начало — центр проёма на земле, перёд (к игрокам во дворе) — −Y Blender.
Имена объектов в Blender — <Регион>__<Часть>, чтобы три пары ворот не путались в общем OBJ;
в манифесте часть называется по контракту (Door, Sign, Lock, Frame), а имя группы OBJ — в поле src.
"""
import math

from mathutils import Vector

import build_style_test as bst

GATE_W, GATE_H = 12.0, 10.0  # створка
POST_X = 6.6


def frame(tag):
    p = bst.Part(f'{tag}__Frame')
    for sx in (-1, 1):
        x = sx * POST_X
        p.box((x, 0, 6.5), (1.0, 1.0, 13.0), 'metal_03')  # стойки-двутавры
        p.box((x, 0, 0.4), (1.8, 1.8, 0.8), 'asphalt_09')  # бетонные башмаки
        p.box((x + sx * 1.2, 0.9, 3.0), (0.3, 0.3, 6.6), 'metal_04', bst.R('Y', sx * 22))  # подкосы
        p.box((x, -0.52, 5.0 + sx), (0.6, 0.06, 1.4), 'rust_07')  # ржавчина на стойке
    p.box((0, 0, 13.4), (POST_X * 2 + 1.6, 1.0, 0.8), 'metal_03')  # верхняя балка
    p.box((0, -0.52, 13.4), (3.0, 0.06, 0.5), 'rust_08')
    for x in (-3.2, 3.2):  # кронштейны таблички
        p.box((x, -0.5, 14.2), (0.25, 0.25, 1.2), 'metal_05')
    return p


def door(tag):
    p = bst.Part(f'{tag}__Door')
    z0, z1, hw = 0.3, 0.3 + GATE_H, GATE_W / 2
    zc = (z0 + z1) / 2
    for x, w in ((-hw + 0.15, 0.3), (hw - 0.15, 0.3)):
        p.box((x, 0, zc), (w, 0.4, GATE_H), 'metal_04')  # рама створки
    for z in (z0 + 0.15, zc, z1 - 0.15):
        p.box((0, 0, z), (GATE_W, 0.4, 0.3), 'metal_04')
    # профлист: полосы двух тонов ржавчины
    n = 10
    for i in range(n):
        x = -hw + 0.3 + (GATE_W - 0.6) * (i + 0.5) / n
        p.box((x, 0.02 if i % 2 else -0.02, zc), ((GATE_W - 0.6) / n, 0.2, GATE_H - 0.3),
              ('rust_06', 'metal_05', 'rust_08', 'metal_06')[i % 4])
    ang = math.degrees(math.atan2(GATE_H - 0.6, GATE_W - 0.6))
    p.box((0, -0.25, zc), (math.hypot(GATE_W, GATE_H) - 1.2, 0.15, 0.3), 'metal_04', bst.R('Y', -ang))  # раскос
    for z in (z0 + 1.5, z1 - 1.5):  # петли
        p.box((-hw - 0.1, 0, z), (0.4, 0.5, 0.6), 'metal_02')
    return p, Vector((-hw, 0, zc))


def lock(tag):
    """Видна, пока ворота закрыты: доски крест-накрест, цепь и замок."""
    p = bst.Part(f'{tag}__Lock')
    zc = 0.3 + GATE_H / 2
    for s in (-1, 1):
        p.box((0, -0.45, zc), (math.hypot(GATE_W, GATE_H) * 0.8, 0.2, 0.6), 'wood_08', bst.R('Y', s * 38))
    for i in range(9):  # цепь: звенья вперемешку
        x = -2.4 + i * 0.6
        p.box((x, -0.6, zc + 0.6 - abs(i - 4) * 0.08), (0.55, 0.12, 0.3) if i % 2 else (0.55, 0.3, 0.12), 'metal_09')
    p.box((0, -0.75, zc - 0.2), (0.7, 0.3, 0.8), 'metal_07')  # замок
    p.box((0, -0.75, zc + 0.35), (0.45, 0.12, 0.4), 'metal_10')
    return p


def pictogram(p, region, z, y):
    """Пиктограмма региона на табличке (без текста: игра на двух языках)."""
    if region == 'City':
        for x, h in ((-1.6, 1.6), (-0.4, 2.2), (0.9, 1.3), (1.9, 1.8)):
            p.box((x, y, z - 1.1 + h / 2), (0.9, 0.1, h), 'neutral_03')
            for k in range(int(h / 0.5)):
                p.box((x, y - 0.06, z - 0.9 + k * 0.5), (0.3, 0.05, 0.2), 'signal_yellow_light')
    elif region == 'Sea':
        for row, cell in ((0.0, 'water_02'), (-0.6, 'water_05')):
            for i in range(5):
                x = -2.0 + i * 1.0
                p.prism([Vector((x - 0.5, y, z + row - 0.2)), Vector((x, y, z + row + 0.25)),
                         Vector((x + 0.5, y, z + row - 0.2))], (0, -0.1, 0), cell)
        p.prism([Vector((-0.6, y, z + 0.35)), Vector((0.8, y, z + 0.35)), Vector((0.1, y, z + 1.1))],
                (0, -0.1, 0), 'neutral_14')  # парус
    else:
        for x, h, w in ((-1.0, 2.0, 2.6), (1.0, 1.5, 2.2)):
            base = z - 1.1
            p.prism([Vector((x - w / 2, y, base)), Vector((x + w / 2, y, base)), Vector((x, y, base + h))],
                    (0, -0.1, 0), 'asphalt_06')
            p.prism([Vector((x - w * 0.14, y - 0.1, base + h * 0.72)), Vector((x + w * 0.14, y - 0.1, base + h * 0.72)),
                     Vector((x, y - 0.1, base + h))], (0, -0.05, 0), 'neutral_15')  # снег


PLATE = {'City': 'faded_yellow_2', 'Sea': 'faded_blue_2', 'Mountains': 'faded_teal_2'}


def sign(tag, region):
    p = bst.Part(f'{tag}__Sign')
    z = 15.4
    p.box((0, -0.65, z), (7.6, 0.3, 3.2), 'wood_05')  # доска
    p.box((0, -0.82, z), (6.8, 0.06, 2.6), PLATE[region])  # крашеная пластина
    p.box((2.6, -0.86, z + 0.9), (0.9, 0.04, 0.5), 'rust_06')  # облезлая краска
    pictogram(p, region, z, -0.9)
    return p


def gate(region, open_by_default):
    tag = f'Gate{region}'
    fr, dr, lk, sg = frame(tag), None, lock(tag), sign(tag, region)
    dr, hinge = door(tag)
    name = f'Lobby_Door_{region}'
    return {
        'name': name, 'category': 'Lobby', 'primary': 'Frame', 'parts': [fr, dr, sg, lk],
        'pivots': {f'{tag}__Door': hinge}, 'attachments': {'Entrance': ('Frame', Vector((0, -5.0, 0)))},
        'colliders': [], 'attributes': {'Region': region, 'OpenByDefault': open_by_default},
        'studio': {'Frame': {'CollisionFidelity': 'Box'}, 'Door': {'CanCollide': True, 'CollisionFidelity': 'Box'},
                   'Sign': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False},
                   'Lock': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False}},
    }
