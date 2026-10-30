#!/usr/bin/env python3
"""TEST_01 §6: тестовые меши TestPaletteBox.obj, TestUVBleed.obj и TestSkinBox.obj.

TestSkinBox — дополнение к §6 для тестов E и F: куб 4×4×4, на каждой грани полная UV 0..1
(скин 1024² ложится на грань целиком; на TestPaletteBox грани сжаты в точку и скин не виден).

UV — по palette.json (соглашение Blender/OBJ, V снизу), плоские нормали.
Ячейки — только по slug. Обычно вызывается из gen_palette.py; отдельно:
python3 gen_test_mesh.py [--out <папка assets>]
"""
import argparse
import json
import sys
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

SIZE = 512


def mtl(tex):
    return (f'newmtl {tex}\nKd 1 1 1\nKa 0 0 0\nKs 0 0 0\nd 1\nillum 1\n'
            f'map_Kd ../../textures/models/{tex}.png\n').encode()


def fx(x, n):
    """Как Number.prototype.toFixed(n) в JS."""
    return str(Decimal(x).quantize(Decimal(1).scaleb(-n), ROUND_HALF_UP))


def px_uv(x0, y0, x1, y1):
    """Пиксельный прямоугольник -> [u_min, v_min, u_max, v_max]."""
    return [x0 / SIZE, 1 - y1 / SIZE, x1 / SIZE, 1 - y0 / SIZE]


def point(uv):
    return [uv[0], uv[1], uv[0], uv[1]]


def obj(name, faces, tex='T_Palette_Main', comment='UV по palette.json, V снизу, плоские нормали'):
    """faces: [(group, 4 вершины против часовой, нормаль, uv_rect)]; углы UV: BL, BR, TR, TL."""
    lines = [f'# {name} — {comment}', f'mtllib {name}.mtl', f'o {name}', f'usemtl {tex}']
    for n, (group, verts, normal, (u0, v0, u1, v1)) in enumerate(faces, 1):
        lines.append(f'g {group}')
        lines += ['v ' + ' '.join(fx(c, 4) for c in v) for v in verts]
        lines += [f'vt {fx(u, 6)} {fx(v, 6)}' for u, v in ((u0, v0), (u1, v0), (u1, v1), (u0, v1))]
        lines.append('vn ' + ' '.join(str(c) for c in normal))
        base = (n - 1) * 4
        lines.append('f ' + ' '.join(f'{base + i}/{base + i}/{n}' for i in range(1, 5)))
    return ('\n'.join(lines) + '\n').encode()


def build(pal):
    E = {e['name']: e for e in pal['entries']}

    def cell_px(name):
        x, y, _, _ = E[name]['px_rect']
        return x, y

    grad = E['grad_sand_terracotta']
    gx = grad['px_rect'][0] + grad['px_rect'][2] / 2
    gs = grad['uv_safe_rect']
    neg_x = [(gx - 6) / SIZE, gs[1], (gx + 6) / SIZE, gs[3]]

    # −Z / плитка 2: 20×20 внутри skin_6, 1 px от правого края (сосед справа — denim_1), 6 px сверху и снизу
    sx, sy = cell_px('skin_6')
    edge = px_uv(sx + 11, sy + 6, sx + 31, sy + 26)
    cross = px_uv(sx + 22, sy + 6, sx + 42, sy + 26)

    s = 2
    cube = [  # грань, 4 вершины против часовой снаружи, нормаль
        ('PosY', [(-s, s, s), (s, s, s), (s, s, -s), (-s, s, -s)], (0, 1, 0)),
        ('NegY', [(-s, -s, -s), (s, -s, -s), (s, -s, s), (-s, -s, s)], (0, -1, 0)),
        ('PosX', [(s, -s, s), (s, -s, -s), (s, s, -s), (s, s, s)], (1, 0, 0)),
        ('NegX', [(-s, -s, -s), (-s, -s, s), (-s, s, s), (-s, s, -s)], (-1, 0, 0)),
        ('PosZ', [(-s, -s, s), (s, -s, s), (s, s, s), (-s, s, s)], (0, 0, 1)),
        ('NegZ', [(s, -s, -s), (-s, -s, -s), (-s, s, -s), (s, s, -s)], (0, 0, -1)),
    ]
    box_uv = [  # в порядке граней cube
        ('sand_08', point(E['sand_08']['uv_center'])),
        ('asphalt_04', point(E['asphalt_04']['uv_center'])),
        ('signal_orange_base', E['signal_orange_base']['uv_safe_rect']),
        ('grad_sand_terracotta', neg_x),
        ('weapon_steel', point(E['weapon_steel']['uv_center'])),
        ('BAD_skin_6_edge', edge),
    ]
    box = obj('TestPaletteBox', [(f'{g}_{slug}', v, n, uv) for (g, v, n), (slug, uv) in zip(cube, box_uv)])

    def tile(x0):
        return [(x0, 0, 0), (x0 + 8, 0, 0), (x0 + 8, 8, 0), (x0, 8, 0)]
    bleed = obj('TestUVBleed', [
        ('Tile1_control', tile(-14), (0, 0, 1), E['skin_6']['uv_safe_rect']),
        ('Tile2_edge_1px', tile(-4), (0, 0, 1), edge),
        ('Tile3_cross_border', tile(6), (0, 0, 1), cross),
    ])
    skin = obj('TestSkinBox', [(f'{g}_full_uv', v, n, [0, 0, 1, 1]) for g, v, n in cube],
               'T_VehicleSkin_Test', 'полная UV 0..1 на каждой грани (тесты E, F), плоские нормали')
    return {'source/test/TestPaletteBox.obj': box, 'source/test/TestPaletteBox.mtl': mtl('T_Palette_Main'),
            'source/test/TestUVBleed.obj': bleed, 'source/test/TestUVBleed.mtl': mtl('T_Palette_Main'),
            'source/test/TestSkinBox.obj': skin, 'source/test/TestSkinBox.mtl': mtl('T_VehicleSkin_Test')}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', type=Path, default=Path(__file__).resolve().parent.parent)
    out = ap.parse_args().out.resolve()
    pal = json.loads((out / 'palette' / 'palette.json').read_text())
    for rel, data in build(pal).items():
        p = out / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
        print(p)


if __name__ == '__main__':
    sys.exit(main())
