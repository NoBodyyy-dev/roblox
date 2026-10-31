"""Style test (ASSETS_PROMPT §2): небольшой дом, стартовый седан, скала.

Запуск (Blender 5.2+):
  blender --background --factory-startup --python assets/tools/style_test/build_style_test.py

Единицы Blender = studs. Ось вверх Z, перёд модели смотрит в −Y Blender.
В Roblox: (x, y, z)_blender → (−x, z, y)_roblox, перёд = −Z (LookVector), низ на Y = 0.
Это то же соответствие, что дал импорт OBJ в TEST_01 (REPORT §1: X и Z обращены).

Палитровые части: UV каждого полигона — остров ISLAND_PX px в центре ячейки palette.json.
Body / Hood / Trunk: без текстуры, краска — Color с сервера (контракт Body, issue #2).
UV Body — развёртка 0..1 по видам (бок, верх, перёд, зад) под будущие скины SurfaceAppearance.

Выход: assets/source/style_test/ — <Asset>.obj/.mtl, <Asset>.fbx, <Asset>.manifest.json,
StyleTest.blend, preview/*.png (рендер Blender, не замена скриншотам Studio).
"""
import json
import math
import random
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / 'assets'
OUT = ASSETS / 'source' / 'style_test'
PALETTE_PNG = ASSETS / 'textures' / 'models' / 'T_Palette_Main.png'
PAL = json.loads((ASSETS / 'palette' / 'palette.json').read_text(encoding='utf-8'))
CELLS = {e['name']: e for e in PAL['entries']}
SIZE = PAL['size'][0]
ISLAND_PX = 8
NO_CELL = -1
CELL_IDS = {n: i for i, n in enumerate(CELLS)}
CELL_NAMES = list(CELLS)

# Blender → Roblox
P = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def to_rbx(v):
    v = Vector(v)
    return [round(-v.x, 4), round(v.z, 4), round(v.y, 4)]


def size_rbx(s):
    return [round(s[0], 4), round(s[2], 4), round(s[1], 4)]


# ---------------------------------------------------------------- геометрия

class Part:
    """Один будущий MeshPart: bmesh + слой ячейки палитры на полигон."""

    def __init__(self, name, textured=True):
        self.name = name
        self.textured = textured
        self.bm = bmesh.new()
        self.cell = self.bm.faces.layers.int.new('cell')
        self.pending = []  # (face, cell_spec)

    def poly(self, pts, cell, ref=None, outward=True):
        vs = [self.bm.verts.new(p) for p in pts]
        f = self.bm.faces.new(vs)
        if ref is not None:
            orient(f, ref, outward)
        self.pending.append((f, cell))
        return f

    def solid(self, verts, faces, cell, center=None):
        """Выпуклое тело: verts — точки, faces — индексы; нормали наружу от центра."""
        vs = [self.bm.verts.new(p) for p in verts]
        c = center or sum((Vector(p) for p in verts), Vector()) / len(verts)
        for idx in faces:
            f = self.bm.faces.new([vs[i] for i in idx])
            orient(f, c, True)
            self.pending.append((f, cell))

    def box(self, c, s, cell, rot=None):
        c, h = Vector(c), Vector(s) / 2
        m = rot.to_3x3() if rot is not None else Matrix.Identity(3)
        corners = [c + m @ Vector((sx * h.x, sy * h.y, sz * h.z))
                   for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        # индексы: x-major, y, z
        faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
        self.solid(corners, faces, cell, c)

    def prism(self, base, d, cell):
        """Призма: base — точки выпуклого многоугольника, d — вектор выдавливания."""
        n = len(base)
        top = [Vector(p) + Vector(d) for p in base]
        faces = [tuple(range(n)), tuple(range(n, 2 * n))]
        faces += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        self.solid([Vector(p) for p in base] + top, faces, cell)

    def cyl(self, c, r, length, sides, cell, axis='X', phase=0.5):
        c = Vector(c)
        ring = []
        for k in range(sides):
            a = 2 * math.pi * (k + phase) / sides
            u, v = r * math.cos(a), r * math.sin(a)
            ring.append({'X': Vector((0, u, v)), 'Y': Vector((u, 0, v)), 'Z': Vector((u, v, 0))}[axis])
        d = {'X': Vector((1, 0, 0)), 'Y': Vector((0, 1, 0)), 'Z': Vector((0, 0, 1))}[axis] * length
        self.prism([c - d / 2 + p for p in ring], d, cell)

    def finish(self):
        bm = self.bm
        bm.normal_update()
        for f, spec in self.pending:
            name = spec(f.normal, f.calc_center_median()) if callable(spec) else spec
            f[self.cell] = CELL_IDS[name] if name else NO_CELL
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        bm.normal_update()
        return bm


def orient(f, ref, outward):
    f.normal_update()
    d = f.calc_center_median() - Vector(ref)
    if (f.normal.dot(d) < 0) == outward:
        f.normal_flip()


def by_normal(top, side, bottom=None, k=0.55):
    def spec(n, _c):
        if n.z > k:
            return top
        if bottom and n.z < -k:
            return bottom
        return side
    return spec


def R(axis, deg):
    return Matrix.Rotation(math.radians(deg), 4, axis)


def rnd_rot(rng, tilt=20):
    return R('Z', rng.uniform(0, 360)) @ R('X', rng.uniform(-tilt, tilt)) @ R('Y', rng.uniform(-tilt, tilt))


# износ (§2: цветом и геометрией): плоские палитровые заплатки поверх поверхности, координаты 2D (a, z)

def blob(c, w, h, rng, k=7, jag=0.3):
    """Неровное пятно: штукатурка, ржавчина, грязь."""
    c, pts = Vector(c), []
    for i in range(k):
        a = 2 * math.pi * (i + rng.uniform(-0.25, 0.25)) / k
        r = 1 - rng.uniform(0, jag)
        pts.append(c + Vector((math.cos(a) * w / 2 * r, math.sin(a) * h / 2 * r)))
    return pts


def drip(top, w, length, rng):
    """Потёк вниз от точки top."""
    t = Vector(top)
    return [t + Vector((-w / 2, 0)), t + Vector((w / 2, 0)), t + Vector((w * 0.2, -length * rng.uniform(0.5, 0.7))),
            t + Vector((0, -length)), t + Vector((-w * 0.25, -length * rng.uniform(0.6, 0.85)))]


def band(a0, a1, z, hmin, hmax, rng, step=0.8):
    """Полоса грязи снизу: ровный низ на высоте z, рваный верх."""
    n = max(2, int((a1 - a0) / step) + 1)
    tops = [Vector((a0 + (a1 - a0) * i / (n - 1), z + rng.uniform(hmin, hmax))) for i in range(n)]
    return [Vector((a0, z)), Vector((a1, z))] + tops[::-1]


class Plane:
    """Плоскость поверхности для заплаток: (a, z) → точка в Blender, нормаль наружу."""

    def __init__(self, fn, nrm):
        self.fn, self.n = fn, Vector(nrm)

    def put(self, part, pts2d, cell, off):
        pts = [self.fn(p.x, p.y) + self.n * off for p in pts2d]
        c = sum(pts, Vector()) / len(pts)
        part.poly(pts, cell, c - self.n)


# ---------------------------------------------------------------- UV

def island_uv(bm, uvl, cl):
    """Палитра: каждый треугольник — остров ISLAND_PX px вокруг uv_center ячейки."""
    h = ISLAND_PX / 2 / SIZE
    for f in bm.faces:
        cid = f[cl]
        if cid == NO_CELL:
            continue
        cu, cv = CELLS[CELL_NAMES[cid]]['uv_center']
        n = f.normal
        t = (n.cross(Vector((0, 0, 1))) if abs(n.z) < 0.9 else n.cross(Vector((1, 0, 0)))).normalized()
        b = n.cross(t)
        pts = [(l.vert.co.dot(t), l.vert.co.dot(b)) for l in f.loops]
        us, vs = [p[0] for p in pts], [p[1] for p in pts]
        span = max(max(us) - min(us), max(vs) - min(vs), 1e-6)
        mu, mv = (max(us) + min(us)) / 2, (max(vs) + min(vs)) / 2
        for l, (u, v) in zip(f.loops, pts):
            l[uvl].uv = (cu + (u - mu) / span * 2 * h, cv + (v - mv) / span * 2 * h)


def check_palette_uv(bm, uvl, cl):
    """Все UV палитровых полигонов внутри uv_safe_rect своей ячейки; минимальный отступ до края ячейки в px."""
    bad, min_px = 0, 1e9
    for f in bm.faces:
        cid = f[cl]
        if cid == NO_CELL:
            continue
        e = CELLS[CELL_NAMES[cid]]
        u0, v0, u1, v1 = e['uv_safe_rect']
        x, y, w, hgt = e['px_rect']
        for l in f.loops:
            u, v = l[uvl].uv
            if not (u0 - 1e-6 <= u <= u1 + 1e-6 and v0 - 1e-6 <= v <= v1 + 1e-6):
                bad += 1
            px, py = u * SIZE, (1 - v) * SIZE
            min_px = min(min_px, px - x, x + w - px, py - y, y + hgt - py)
    return bad, round(min_px, 2)


def body_uv(bm, uvl, center, split_z):
    """UV Body под скины: проекции по видам, острова упакованы полками в 0..1 с полями.

    Группы: right(+X/Blender = левый борт в Roblox), left, top_deck, top_roof, front, rear, bottom, inner_*.
    Внутри группы — ортопроекция с сохранением ориентации (без зеркала)."""
    proj = {
        '+X': lambda p: (p.y, p.z), '-X': lambda p: (-p.y, p.z),
        '+Y': lambda p: (-p.x, p.z), '-Y': lambda p: (p.x, p.z),
        '+Z': lambda p: (-p.y, p.x), '-Z': lambda p: (p.y, p.x),
    }
    groups = {}
    for f in bm.faces:
        n, c = f.normal, f.calc_center_median()
        ax = max(range(3), key=lambda i: abs(n[i]))
        key = ('+' if n[ax] > 0 else '-') + 'XYZ'[ax]
        name = key
        if key == '+Z':
            name += '_roof' if c.z > split_z else '_deck'
        if key in ('+Y', '-Y') and abs(c.y) < 7.0:
            name += f'@{c.y:.1f}'  # торцы арок не накладываются на перёд и зад
        if n.dot(c - center) < 0:
            name = 'inner' + name
        groups.setdefault(name, (key, []))[1].append(f)
    raw = {}
    for name, (key, faces) in groups.items():
        pts = {id(l): proj[key](l.vert.co) for f in faces for l in f.loops}
        us = [p[0] for p in pts.values()]
        vs = [p[1] for p in pts.values()]
        raw[name] = (faces, key, min(us), min(vs), max(us) - min(us), max(vs) - min(vs))
    margin, gap = 16 / 1024, 16 / 1024

    def pack(s):
        order = sorted(raw, key=lambda k: -raw[k][5])
        x, y, shelf, place = margin, margin, 0, {}
        for k in order:
            w, h = raw[k][4] * s, raw[k][5] * s
            if x + w > 1 - margin:
                x, y, shelf = margin, y + shelf + gap, 0
            place[k] = (x, y)
            x += w + gap
            shelf = max(shelf, h)
        return place if y + shelf <= 1 - margin else None

    s = 0.2
    while pack(s) is None:
        s *= 0.98
    place = pack(s)
    for k, (faces, key, mu, mv, _, _) in raw.items():
        ox, oy = place[k]
        for f in faces:
            for l in f.loops:
                u, v = proj[key](l.vert.co)
                l[uvl].uv = (ox + (u - mu) * s, oy + (v - mv) * s)
    return {'texel_studs_per_uv': round(1 / s, 3), 'px_per_stud_1024': round(s * 1024, 1),
            'groups': {k: [round(c, 4) for c in (place[k][0], place[k][1], raw[k][4] * s, raw[k][5] * s)]
                       for k in raw}}


def box_uv(bm, uvl):
    """Hood / Trunk: простая проекция сверху (части без текстуры, UV только чтобы была)."""
    xs = [v.co.x for v in bm.verts]
    ys = [v.co.y for v in bm.verts]
    w = max(max(xs) - min(xs), max(ys) - min(ys), 1e-6)
    for f in bm.faces:
        for l in f.loops:
            l[uvl].uv = (0.05 + 0.9 * (l.vert.co.y - min(ys)) / w, 0.05 + 0.9 * (l.vert.co.x - min(xs)) / w)


# ---------------------------------------------------------------- материалы

def materials():
    img = bpy.data.images.load(str(PALETTE_PNG), check_existing=True)

    def tex_mat(name, alpha=1.0):
        m = bpy.data.materials.new(name)
        try:
            m.use_nodes = True
        except AttributeError:
            pass
        nt = m.node_tree
        bsdf = next(n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED')
        t = nt.nodes.new('ShaderNodeTexImage')
        t.image = img
        t.interpolation = 'Linear'
        nt.links.new(t.outputs['Color'], bsdf.inputs['Base Color'])
        bsdf.inputs['Roughness'].default_value = 0.9
        if alpha < 1:
            bsdf.inputs['Alpha'].default_value = alpha
            m.diffuse_color = (0.3, 0.45, 0.5, alpha)
        return m

    paint = bpy.data.materials.new('Paint_White')
    paint.diffuse_color = (1, 1, 1, 1)
    collider = bpy.data.materials.new('Collider')
    collider.diffuse_color = (1, 0, 1, 0.2)
    return {'palette': tex_mat('T_Palette_Main'), 'glass': tex_mat('T_Palette_Main_Glass', 0.45),
            'paint': paint, 'collider': collider}


# ---------------------------------------------------------------- седан

WHEEL_R = 1.2
FLAT_AXLE = 0.7  # ось спущенного колеса


def wheel(nm, x, y, flat=False):
    cz = FLAT_AXLE if flat else WHEEL_R
    w = Part(nm)
    w.cyl((x, y, cz), WHEEL_R, 0.85, 10, lambda n, _c: 'neutral_05' if abs(n.x) > 0.9 else 'neutral_02')
    w.cyl((x, y, cz), 0.62, 0.92, 10, 'rust_05' if flat else 'metal_06')
    if flat:  # шина смята снизу и раздута в стороны, диск почти на земле
        for v in w.bm.verts:
            if Vector((v.co.y - y, v.co.z - cz)).length > 0.9 and v.co.z < cz:
                v.co.z = max(cz - (cz - v.co.z) * 0.62, 0.02)
                v.co.x += 0.1 if v.co.x > x else -0.1
    return w


def sedan_wheel_flat():
    """Вариант колеса седана: спущенное. Код ставит его вместо Wheel_XX и опускает ось на AxleDrop."""
    return {'name': 'Sedan_Wheel_Flat', 'category': 'Vehicles', 'primary': 'Wheel_Flat',
            'parts': [wheel('Wheel_Flat', 0, 0, flat=True)],
            'pivots': {'Wheel_Flat': Vector((0, 0, FLAT_AXLE))}, 'model_pivot': Vector((0, 0, FLAT_AXLE)),
            'attachments': {}, 'colliders': [],
            'attributes': {'Vehicle': 'Sedan', 'AxleDrop': round(WHEEL_R - FLAT_AXLE, 3)},
            'studio': {'*': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False}}}


def sedan():
    # профиль кузова вдоль Y (перёд = −Y): ключевые точки полуширины, низа и верха палубы
    def lerp(keys):
        def f(y):
            for (y0, a), (y1, b) in zip(keys, keys[1:]):
                if y0 <= y <= y1:
                    return a + (b - a) * (y - y0) / (y1 - y0)
            return keys[0][1] if y < keys[0][0] else keys[-1][1]
        return f

    arch = []
    for yc in (-4.7, 4.7):  # арки колёс: R колеса 1.2, центр z 1.2, зазор
        arch += [(yc - 1.55, 0.75), (yc - 1.45, 1.2), (yc - 1.05, 2.1), (yc, 2.6),
                 (yc + 1.05, 2.1), (yc + 1.45, 1.2), (yc + 1.55, 0.75)]
    wkeys = [(-7.6, 2.75), (-7.4, 3.0), (-6.6, 3.15), (-6.25, 3.2), (6.25, 3.2), (6.6, 3.15), (7.4, 3.0),
             (7.6, 2.8)]
    bkeys = [(-7.6, 1.05), (-7.4, 0.8), (-6.6, 0.75)] + arch + [(6.6, 0.8), (7.4, 0.85), (7.6, 1.1)]
    deck = [(-7.6, 2.55), (-7.4, 2.75), (-6.6, 2.92), (-4.7, 3.03), (-2.4, 3.1), (4.4, 3.13), (6.6, 3.1),
            (7.4, 3.0), (7.6, 2.85)]
    ztop, width, zbot = lerp(deck), lerp(wkeys), lerp(bkeys)
    ys = sorted({round(y, 3) for y, _ in wkeys + bkeys + deck} | {1.0})
    st = [(y, width(y), zbot(y)) for y in ys]

    def section(y, w, zb):
        zt = ztop(y)
        zc = min(zb + 0.25, zt - 0.35)
        pts = [(-(w - 0.3), zb), (w - 0.3, zb), (w, zc), (w, zt - 0.3), (w - 0.35, zt), (-(w - 0.35), zt),
               (-w, zt - 0.3), (-w, zc)]
        return [Vector((x, y, z)) for x, z in pts]

    body = Part('Body', textured=False)
    secs = [section(*s) for s in st]
    vrows = [[body.bm.verts.new(p) for p in sec] for sec in secs]
    cab0, cab1 = -2.4, 4.4
    for i in range(len(secs) - 1):
        for k in range(8):
            if k == 4 and st[i][0] >= cab0 - 1e-6 and st[i + 1][0] <= cab1 + 1e-6:
                continue  # проём палубы под салоном (видно интерьер через стекло)
            q = [vrows[i][k], vrows[i][(k + 1) % 8], vrows[i + 1][(k + 1) % 8], vrows[i + 1][k]]
            f = body.bm.faces.new(q)
            c = f.calc_center_median()
            orient(f, Vector((0, c.y, 1.9)), True)
            body.pending.append((f, None))
    for row in (vrows[0], vrows[-1]):
        f = body.bm.faces.new(row)
        orient(f, Vector((0, 0, 1.9)), True)
        body.pending.append((f, None))

    # салон: стекло — выпуклая оболочка, крыша и стойки — Body
    zr = 5.3
    hull_b = [(2.8, cab0, 3.1), (-2.8, cab0, 3.1), (-2.8, cab1, 3.13), (2.8, cab1, 3.13)]
    hull_t = [(2.3, -0.7, zr), (-2.3, -0.7, zr), (-2.3, 2.6, zr), (2.3, 2.6, zr)]
    glass = Part('Glass')
    glass_c = Vector((0, 1.0, 4.0))
    glass.solid(hull_b + hull_t, [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (4, 5, 6, 7)], 'water_04', glass_c)
    # правый (+X Blender) борт: переднее стекло целое, заднее выбито — остались осколки по краям
    gb0, gb1 = Vector(hull_b[0]), Vector(hull_b[3])
    gt0, gt1 = Vector(hull_t[0]), Vector(hull_t[3])

    def side_pt(s, tt):  # s: 0 у лобового → 1 у заднего, tt: 0 низ → 1 верх
        return gb0.lerp(gb1, s).lerp(gt0.lerp(gt1, s), tt)

    glass.poly([side_pt(0, 0), side_pt(0.52, 0), side_pt(0.52, 1), side_pt(0, 1)], 'water_04', glass_c)
    for sh in ([(0.54, 0), (0.66, 0), (0.58, 0.32)], [(0.66, 0), (0.80, 0), (0.72, 0.18)],
               [(0.80, 0), (0.99, 0), (0.99, 0.14), (0.9, 0.26)], [(0.99, 1), (0.8, 1), (0.99, 0.7)],
               [(0.54, 0.4), (0.54, 0.85), (0.62, 0.6)]):
        glass.poly([side_pt(*p) for p in sh], 'water_04', glass_c)
    body.box((0, 0.95, zr + 0.01), (4.96, 3.66, 0.22), None)

    def pillar(p0, p1, t=0.32):
        p0, p1 = Vector(p0), Vector(p1)
        d = (p1 - p0).normalized()
        a = d.cross(Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))).normalized() * t / 2
        b = d.cross(a).normalized() * t / 2
        base = [p0 + a + b, p0 - a + b, p0 - a - b, p0 + a - b]
        body.prism(base, p1 - p0, None)

    for sx in (1, -1):
        pillar((2.8 * sx, cab0, 3.05), (2.3 * sx, -0.7, zr))
        pillar((2.8 * sx, cab1, 3.08), (2.3 * sx, 2.6, zr))
        pillar((2.78 * sx, 1.15, 3.05), (2.33 * sx, 1.0, zr))

    # капот и багажник: панели на палубе, без текстуры; вмятины и вздутие — сеткой вершин
    def panel(name, y0, y1, hinge_y, bump, nx=4, ny=6):
        p = Part(name, textured=False)
        hw = 2.7
        grid = [[(-hw + 2 * hw * i / nx, y0 + (y1 - y0) * j / ny) for j in range(ny + 1)] for i in range(nx + 1)]
        top, bot = {}, {}
        for i in range(nx + 1):
            for j in range(ny + 1):
                x, y = grid[i][j]
                b = bump(x, y) if 0 < i < nx and 0 < j < ny or bump(x, y) > 0 else 0.0
                bot[i, j] = p.bm.verts.new((x, y, ztop(y) + 0.01 + max(b, 0.0)))
                top[i, j] = p.bm.verts.new((x, y, ztop(y) + 0.16 + b))

        def face(vs, ref):
            f = p.bm.faces.new(vs)
            orient(f, ref, True)
            p.pending.append((f, None))

        for i in range(nx):
            for j in range(ny):
                q = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]
                c = sum((top[k].co for k in q), Vector()) / 4
                face([top[k] for k in q], c - Vector((0, 0, 1)))
                c = sum((bot[k].co for k in q), Vector()) / 4
                face([bot[k] for k in q], c + Vector((0, 0, 1)))
        mid_c = Vector((0, (y0 + y1) / 2, ztop((y0 + y1) / 2)))
        edges = [[(i, 0) for i in range(nx + 1)], [(nx, j) for j in range(ny + 1)],
                 [(i, ny) for i in range(nx + 1)], [(0, j) for j in range(ny + 1)]]
        for e in edges:
            for a, b in zip(e, e[1:]):
                face([bot[a], bot[b], top[b], top[a]], mid_c)
        return p, Vector((0, hinge_y, ztop(hinge_y) + 0.16))

    def hood_bump(x, y):  # смятый от удара капот: поперечная складка-«домик» и вмятина сбоку
        ridge = 0.5 * max(0.0, 1 - abs(y + 5.6) / 1.3) * (0.55 + 0.45 * (x + 2.7) / 5.4)
        dent = -0.12 * max(0.0, 1 - (Vector((x - 1.0, y + 3.6)).length / 1.1))
        return ridge + dent

    def trunk_bump(x, y):
        return -0.11 * max(0.0, 1 - (Vector((x + 0.9, y - 6.1)).length / 1.0))

    hood, hood_hinge = panel('Hood', -7.15, -2.55, -2.55, hood_bump)
    trunk, trunk_hinge = panel('Trunk', 4.65, 7.25, 4.65, trunk_bump, 4, 4)

    trim = Part('Trim')
    rng = random.Random(5)
    # перед: бампер оторван с правого края и висит, фара разбита, решётка тёмная, номер погнут
    bump_rot = R('Z', 6) @ R('Y', 8)
    bump_end = Vector((-3.0, -7.55, 1.25))
    trim.box(bump_end + bump_rot.to_3x3() @ Vector((3.0, 0, 0)), (6.0, 0.5, 0.55), 'neutral_06', bump_rot)
    trim.box(bump_end + bump_rot.to_3x3() @ Vector((3.0, -0.26, 0)), (1.3, 0.04, 0.42), 'neutral_11',
             bump_rot @ R('X', 12))
    trim.box((0, -7.63, 2.05), (2.4, 0.1, 0.45), 'neutral_01')  # решётка
    trim.box((2.05, -7.62, 2.2), (0.9, 0.12, 0.42), 'neutral_01')  # разбитая фара
    trim.box((-2.05, -7.62, 2.2), (0.9, 0.12, 0.42), 'faded_yellow_3')
    head = Plane(lambda a, z: Vector((a, -7.68, z)), (0, -1, 0))
    for sh in ([(1.6, 2.41), (2.0, 2.41), (1.6, 2.1)], [(2.5, 1.99), (2.5, 2.3), (2.2, 1.99)]):
        head.put(trim, [Vector(p) for p in sh], 'neutral_13', 0.02)
    # зад: бампер выцвел и с ржавчиной, одного фонаря нет
    trim.box((0, 7.55, 1.25), (6.0, 0.5, 0.55), 'neutral_05')
    trim.box((0, 7.81, 1.25), (1.3, 0.04, 0.42), 'neutral_12')
    trim.box((2.05, 7.62, 2.4), (0.9, 0.12, 0.42), 'faded_red_0')
    trim.box((-2.05, 7.62, 2.4), (0.9, 0.12, 0.42), 'neutral_02')
    rear = Plane(lambda a, z: Vector((-a, 7.8, z)), (0, 1, 0))
    rear.put(trim, blob((-2.2, 1.25), 1.1, 0.42, rng), 'rust_06', 0.02)
    trim.box((-1.8, 7.75, 0.9), (0.3, 0.5, 0.3), 'rust_04')  # выхлоп
    trim.box((3.3, -2.15, 2.95), (0.5, 0.25, 0.35), 'neutral_04', R('Y', 55))  # зеркало висит
    trim.box((-3.25, -2.1, 3.3), (0.2, 0.15, 0.2), 'neutral_04')  # от второго остался кронштейн
    for sx in (1, -1):
        trim.box((3.215 * sx, 0.0, 1.9), (0.06, 6.0, 0.16), 'neutral_05')  # молдинг между арками
        for y in (-1.0, 2.0):
            trim.box((3.225 * sx, y, 2.6), (0.06, 0.45, 0.12), 'neutral_07')  # ручки
        for y in (cab0, 1.15, 3.0):
            trim.box((3.21 * sx, y, 2.05), (0.04, 0.06, 1.5), 'neutral_02')  # щели дверей
    # износ кузова — отдельной палитровой геометрией поверх белого Body (Body и его UV не меняются):
    # ржавчина по аркам, пятна ржавчины, грязь на порогах, пыль и ржавчина на крыше
    for sx in (1, -1):
        sp = Plane(lambda a, z, sx=sx: Vector((sx * 3.2, a, z)), (sx, 0, 0))
        for yc in (-4.7, 4.7):
            ys_ = [yc + d for d in (-1.55, -1.45, -1.05, -0.5, 0.0, 0.5, 1.05, 1.45, 1.55)]
            low = [min(zbot(y) + 0.25, ztop(y) - 0.35) for y in ys_]
            up = [min(z + rng.uniform(0.22, 0.5), ztop(y) - 0.31) for y, z in zip(ys_, low)]
            pts = [Vector((y, z)) for y, z in zip(ys_, low)] + [Vector((y, z)) for y, z in zip(ys_[::-1], up[::-1])]
            sp.put(trim, pts, 'rust_05' if yc < 0 else 'rust_07', 0.05)
        sp.put(trim, band(-3.1, 3.1, 1.0, 0.2, 0.5, rng, 0.7), 'sand_04', 0.05)
        spots = ((-2.0, 2.2, 0.7, 0.45), (0.4, 1.75, 0.6, 0.35), (2.3, 2.3, 0.5, 0.4)) if sx > 0 else             ((-1.2, 1.75, 0.6, 0.4), (1.8, 2.2, 0.7, 0.45))
        for y, z, w, h in spots:
            sp.put(trim, blob((y, z), w, h, rng, 8, 0.45), 'rust_08', 0.06)
            sp.put(trim, blob((y + rng.uniform(-0.2, 0.2) * w, z - 0.15 * h), w * 0.45, h * 0.6, rng, 5, 0.4),
                   'rust_03', 0.07)
    roof = Plane(lambda a, z: Vector((a, z, zr + 0.12)), (0, 0, 1))
    roof.put(trim, blob((-0.2, 1.3), 3.0, 2.4, rng, 8, 0.2), 'sand_10', 0.015)
    for c, w, h in (((0.9, 0.2), 1.1, 0.8), ((-1.3, 2.1), 0.8, 0.6)):
        roof.put(trim, blob(c, w, h, rng, 8, 0.45), 'rust_07', 0.025)
        roof.put(trim, blob((c[0] + 0.2 * w, c[1] - 0.1 * h), w * 0.45, h * 0.5, rng, 5, 0.4), 'rust_03', 0.035)
    # трещина на лобовом: лучи от точки удара
    wb0, wb1, wt0, wt1 = (Vector(p) for p in (hull_b[0], hull_b[1], hull_t[0], hull_t[1]))
    wc = wb0.lerp(wb1, 0.3).lerp(wt0.lerp(wt1, 0.3), 0.5)
    e1 = (wb1 - wb0).normalized()
    e2 = ((wt0 + wt1) / 2 - (wb0 + wb1) / 2).normalized()
    wn = e1.cross(e2).normalized()
    if wn.dot(wc - glass_c) < 0:
        wn = -wn
    for k in range(7):
        a = 2 * math.pi * (k + rng.uniform(-0.3, 0.3)) / 7
        dr = e1 * math.cos(a) + e2 * math.sin(a)
        pr = wn.cross(dr) * 0.035
        trim.poly([wc + pr + wn * 0.03, wc - pr + wn * 0.03, wc + dr * rng.uniform(0.5, 1.2) + wn * 0.03],
                  'neutral_14', wc - wn)
    # осколки бокового стекла на земле
    gnd = Plane(lambda a, z: Vector((a, z, 0.0)), (0, 0, 1))
    for k in range(5):
        a, b = rng.uniform(3.4, 4.4), rng.uniform(1.4, 4.2)
        gnd.put(trim, [Vector((a, b)), Vector((a + 0.3, b + 0.08)), Vector((a + 0.08, b + 0.26))],
                ('water_08', 'neutral_13')[k % 2], 0.02)
    # интерьер: ванна салона с нормалями внутрь (без верха), сиденья, панель
    x0, y0, y1, zf, zt = 2.84, cab0 + 0.02, cab1 - 0.02, 1.1, 3.06
    tub_c = Vector((0, (y0 + y1) / 2, 2.0))
    for q in ([(-x0, y0, zf), (x0, y0, zf), (x0, y1, zf), (-x0, y1, zf)],
              [(x0, y0, zf), (x0, y1, zf), (x0, y1, zt), (x0, y0, zt)],
              [(-x0, y0, zf), (-x0, y0, zt), (-x0, y1, zt), (-x0, y1, zf)],
              [(-x0, y0, zf), (-x0, y0, zt), (x0, y0, zt), (x0, y0, zf)],
              [(-x0, y1, zf), (x0, y1, zf), (x0, y1, zt), (-x0, y1, zt)]):
        trim.poly([Vector(p) for p in q], 'neutral_02', tub_c, outward=False)
    seat = 'cloth'
    for sx in (1, -1):
        trim.box((1.4 * sx, -0.4, 1.4), (1.6, 1.7, 0.6), seat)
        trim.box((1.4 * sx, 0.55, 2.6), (1.6, 0.4, 2.0), seat, Matrix.Rotation(math.radians(-10), 4, 'X'))
        trim.box((1.4 * sx, 0.75, 3.85), (1.0, 0.3, 0.6), seat)
    trim.box((0, 2.75, 1.4), (4.9, 1.6, 0.6), seat)
    trim.box((0, 3.75, 2.55), (4.9, 0.4, 2.0), seat, Matrix.Rotation(math.radians(-8), 4, 'X'))
    trim.box((0, -1.9, 3.05), (5.5, 0.7, 0.5), 'neutral_03')  # приборная панель
    Plane(lambda a, z: Vector((a, z, 1.7)), (0, 0, 1)).put(trim, blob((1.3, -0.5), 0.9, 0.8, rng), 'sand_12', 0.02)
    Plane(lambda a, z: Vector((a, z, 3.3)), (0, 0, 1)).put(trim, blob((-0.8, -1.9), 2.6, 0.5, rng), 'sand_09', 0.02)

    steering = Part('Steering')
    rot = Matrix.Rotation(math.radians(-50), 4, 'X')
    st_c = Vector((1.4, -1.35, 3.3))
    ring = [st_c + rot.to_3x3() @ Vector((0.5 * math.cos(a), 0.5 * math.sin(a), 0))
            for a in (2 * math.pi * (k + 0.5) / 8 for k in range(8))]
    steering.prism(ring, rot.to_3x3() @ Vector((0, 0, 0.08)), 'neutral_02')
    steering.box(st_c + rot.to_3x3() @ Vector((0, 0, -0.25)), (0.18, 0.18, 0.5), 'neutral_03', rot)

    # все четыре колеса целые; спущенное — отдельный ассет Sedan_Wheel_Flat (ревью PR #4)
    wheels, wheel_pivots = [], {'Steering': st_c}
    for nm, x, y in (('Wheel_FL', 2.85, -4.7), ('Wheel_FR', -2.85, -4.7), ('Wheel_RL', 2.85, 4.7),
                     ('Wheel_RR', -2.85, 4.7)):
        wheels.append(wheel(nm, x, y))
        wheel_pivots[nm] = Vector((x, y, WHEEL_R))  # pivot на оси

    collider = Part('Collider', textured=False)
    cb = collider.bm
    pts = [cb.verts.new(p) for p in
           [(sx * 3.2, sy * 7.8, z) for sx in (1, -1) for sy in (1, -1) for z in (0.75, 3.1)]
           + [(sx * 2.48, y, zr + 0.12) for sx in (1, -1) for y in (-0.88, 2.78)]]
    res = bmesh.ops.convex_hull(cb, input=pts)
    bmesh.ops.delete(cb, geom=res['geom_interior'] + res['geom_unused'], context='VERTS')

    att = {
        'Seat_Driver': (1.4, -0.4, 1.7), 'Seat_1': (-1.4, -0.4, 1.7),
        'Seat_2': (1.6, 2.75, 1.7), 'Seat_3': (0, 2.75, 1.7), 'Seat_4': (-1.6, 2.75, 1.7),
        'Engine': (0, -5.0, 2.3), 'Slot_SparkPlug': (0.5, -4.4, 2.75), 'Slot_Battery': (1.7, -5.9, 2.7),
        'Slot_Radiator': (0, -6.9, 2.4), 'Slot_Oil': (-0.7, -4.9, 2.75), 'Slot_FuelCap': (-3.2, 5.9, 2.75),
        'Cargo': (0, 6.0, 2.6), 'Headlight_L': (2.05, -7.7, 2.2), 'Headlight_R': (-2.05, -7.7, 2.2),
        'Exhaust': (-1.8, 8.0, 0.9),
    }
    parts = [body, glass, trim, hood, trunk, steering] + wheels + [collider]
    return {
        'name': 'Sedan', 'category': 'Vehicles', 'primary': 'Body', 'parts': parts,
        'pivots': {'Hood': hood_hinge, 'Trunk': trunk_hinge, **wheel_pivots},
        'attachments': {k: ('Body', v) for k, v in att.items()}, 'colliders': [],
        'body_split_z': 3.6,
        'studio': {
            'Body': {'Color': [255, 255, 255], 'Material': 'SmoothPlastic', 'TextureID': ''},
            'Hood': {'Color': [255, 255, 255], 'Material': 'SmoothPlastic', 'TextureID': ''},
            'Trunk': {'Color': [255, 255, 255], 'Material': 'SmoothPlastic', 'TextureID': ''},
            'Glass': {'Transparency': 0.35, 'Material': 'SmoothPlastic', 'CanCollide': False},
            'Trim': {'CanCollide': False}, 'Steering': {'CanCollide': False},
            'Collider': {'Transparency': 1, 'CanCollide': True, 'CollisionFidelity': 'Hull'},
            '*': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False},
        },
    }


# ---------------------------------------------------------------- дом

def house():
    """Заброшенный дом: грязные выцветшие стены, пролом, дыра в крыше, выбитые окна, доски, мусор."""
    shell = Part('Shell')
    colliders = []
    WALL, FRAME, SILL, PANE = 'sand_08', 'wood_04', 'wood_05', 'neutral_01'
    BOARDS = ('wood_07', 'wood_09', 'wood_06', 'wood_10')
    PEEL, BRICK, DIRT, STREAK, GLASS = 'neutral_09', 'terracotta_04', 'sand_04', 'sand_06', ('water_07', 'water_09')
    z0, z1, t = 0.6, 11.0, 0.6
    rng = random.Random(3)

    def cbox(c, s, cell, rot=None, collide=True):
        shell.box(c, s, cell, rot)
        if collide:
            colliders.append((Vector(c), Vector(s), rot))

    def wall(axis, fixed, a0, a1, openings):
        cuts = sorted({a0, a1, *[o[0] for o in openings], *[o[1] for o in openings]})
        for p, q in zip(cuts, cuts[1:]):
            mid = (p + q) / 2
            op = next((o for o in openings if o[0] <= mid <= o[1]), None)
            spans = [(z0, z1)] if op is None else [(z0, op[2]), (op[3], z1)]
            for za, zb in spans:
                if zb - za < 1e-3:
                    continue
                c = (mid, fixed, (za + zb) / 2) if axis == 'x' else (fixed, mid, (za + zb) / 2)
                s = (q - p, t, zb - za) if axis == 'x' else (t, q - p, zb - za)
                cbox(c, s, WALL)

    def window(axis, out_sign, fixed, o, state, seed):
        """state: 'broken' — тёмный проём и осколки, 'boarded' — доски, None — дверная коробка."""
        a0, a1, oz0, oz1 = o
        wr = random.Random(seed)
        outer = fixed + out_sign * t / 2
        dpt = out_sign * 0.1
        nax = 'Y' if axis == 'x' else 'X'  # ось нормали стены

        def at(a, z, off=0.0):
            return (a, outer + dpt + off, z) if axis == 'x' else (outer + dpt + off, a, z)

        def sz(along, depth, h):
            return (along, depth, h) if axis == 'x' else (depth, along, h)

        am, zm, aw, zh = (a0 + a1) / 2, (oz0 + oz1) / 2, a1 - a0, oz1 - oz0
        if oz0 > z0 + 0.1:
            shell.box(at(am, oz0 - 0.15, out_sign * 0.05), sz(aw + 0.7, 0.35, 0.3), SILL,
                      R(nax, wr.uniform(-5, 5)))  # подоконник, перекошен
            pane_c = (am, fixed, zm) if axis == 'x' else (fixed, am, zm)
            shell.box(pane_c, sz(aw, 0.1, zh), PANE)  # тёмный проём, стекла нет
        shell.box(at(am, oz1 + 0.15), sz(aw + 0.5, 0.2, 0.3), FRAME)
        for a in (a0 - 0.125, a1 + 0.125):
            shell.box(at(a, zm), sz(0.25, 0.2, zh), FRAME)
        if state == 'broken':  # осколки по краям рамы
            gp = Plane(lambda a, z: Vector((a, fixed, z)) if axis == 'x' else Vector((fixed, a, z)),
                       (0, out_sign, 0) if axis == 'x' else (out_sign, 0, 0))
            j = lambda: wr.uniform(-0.2, 0.2)
            shards = [[(a0, oz0), (a0 + 0.9 + j(), oz0), (a0, oz0 + 1.4 + j())],
                      [(a0 + 1.1, oz0), (a0 + 1.9 + j(), oz0), (a0 + 1.45, oz0 + 0.7 + j())],
                      [(a1, oz1), (a1 - 1.2 + j(), oz1), (a1, oz1 - 1.7 + j())],
                      [(a0, oz1), (a0 + 0.6 + j(), oz1), (a0, oz1 - 0.5)],
                      [(a1, oz0 + 0.5), (a1, oz0 + 1.3 + j()), (a1 - 0.5, oz0 + 0.8)]]
            for i, s in enumerate(shards):
                gp.put(shell, [Vector(p) for p in s], GLASS[i % 2], 0.08)
        elif state == 'boarded':
            for i in range(4):
                z = oz0 + zh * (0.14 + 0.24 * i) + wr.uniform(-0.15, 0.15)
                ang, da = wr.uniform(-16, 16), 0.0
                if i == 3:  # одна доска отошла и висит на гвозде
                    ang, da, z = wr.choice((-1, 1)) * 38, aw * 0.25, z - 0.3
                shell.box(at(am + da, z, out_sign * (0.12 + 0.05 * (i % 2))), sz(aw + 0.9, 0.12, 0.5),
                          BOARDS[wr.randrange(len(BOARDS))], R(nax, ang))

    door = (-2.0, 2.0, z0, 8.6)
    breach = (-1.6, 1.4, z0, 4.4)  # пролом в левой стене (до пола)
    front = [door, (3.5, 6.5, 3.6, 7.6), (-6.5, -3.5, 3.6, 7.6)]
    back = [(-1.5, 1.5, 3.6, 7.6)]
    side = [(-6.5, -3.5, 3.6, 7.6), (3.0, 6.0, 3.6, 7.6)]
    wall('x', -9.7, -8.0, 8.0, front)
    wall('x', 9.7, -8.0, 8.0, back)
    wall('y', 7.7, -9.4, 9.4, side)
    wall('y', -7.7, -9.4, 9.4, side + [breach])
    window('x', -1, -9.7, front[1], 'broken', 1)
    window('x', -1, -9.7, front[2], 'boarded', 2)
    window('x', 1, 9.7, back[0], 'broken', 3)
    window('y', 1, 7.7, side[0], 'boarded', 4)
    window('y', 1, 7.7, side[1], 'broken', 5)
    window('y', -1, -7.7, side[0], 'boarded', 6)
    window('y', -1, -7.7, side[1], 'broken', 7)
    window('x', -1, -9.7, door, None, 8)  # дверная коробка: без подоконника и стекла

    # пролом: рваные края из кусков стены и кирпича, доски крест-накрест, обломки снаружи
    for i, y in enumerate((-1.35, -0.6, 0.15, 0.85)):
        h = rng.uniform(0.4, 1.1)
        shell.box((-7.7, y + rng.uniform(-0.1, 0.1), 4.4 - h / 2 + 0.1), (t * 0.9, rng.uniform(0.6, 0.9), h),
                  BRICK if i % 2 else WALL, R('X', rng.uniform(-18, 18)))
    for y, sgn in ((-1.6, 1), (1.4, -1)):
        for z in (1.2, 2.4, 3.5):
            w = rng.uniform(0.3, 0.7)
            shell.box((-7.7, y + sgn * w / 2 - sgn * 0.05, z + rng.uniform(-0.3, 0.3)), (t * 0.9, w, 0.7),
                      BRICK if z > 2 else WALL, R('X', rng.uniform(-25, 25)))
    for z, ang in ((1.9, 24), (3.0, -20)):
        shell.box((-8.15, -0.1, z), (0.12, 4.0, 0.5), BOARDS[int(z) % 4], R('X', ang))
    for k in range(14):
        s = rng.uniform(0.35, 0.95)
        cbx = Vector((rng.uniform(-10.4, -8.3), rng.uniform(-2.2, 2.0), s * 0.3))
        shell.box(cbx, (s, s * rng.uniform(0.6, 1.0), s * 0.6), (WALL, BRICK, 'sand_06')[k % 3], rnd_rot(rng))
    for k in range(5):
        s = rng.uniform(0.4, 0.8)
        shell.box((rng.uniform(-7.0, -5.8), rng.uniform(-1.5, 1.2), z0 + s * 0.25), (s, s, s * 0.5),
                  (WALL, BRICK)[k % 2], rnd_rot(rng))

    # фундамент, пол, крыльцо (просело и треснуло)
    cbox((0, 0, 0.3), (16.6, 20.6, 0.6), 'sand_04')
    cbox((-1.3, -10.9, 0.175), (2.4, 1.6, 0.35), 'sand_05')
    shell.box((1.25, -10.95, 0.12), (2.5, 1.6, 0.35), 'sand_03', R('Y', -4) @ R('X', 3))
    colliders.append((Vector((1.25, -10.9, 0.175)), Vector((2.5, 1.6, 0.35)), None))
    # фронтоны
    for y in (-10.0, 9.4):
        shell.prism([Vector((-8, y, z1)), Vector((8, y, z1)), Vector((0, y, z1 + 5))], (0, 0.6, 0), WALL)
        shell.box((0, y - 0.05 if y < 0 else y + 0.65, 13.0), (1.4, 0.15, 1.0), 'neutral_02')  # выбитая отдушина

    # крыша: черепица плитками, на левом скате дыра со стропилами, часть плиток сдвинута или упала
    rise, half = 5.0, 9.0
    ang = math.atan2(rise + 0.625, half)
    length = math.hypot(half, rise + 0.625)
    nrow, ncol = 4, 11
    tl, tw = length / nrow, 22.0 / ncol
    holes = {-1: {(1, 3), (2, 3), (1, 4), (2, 4), (2, 5)}, 1: {(2, 7)}}
    shifted = {-1: {(1, 2), (3, 4), (0, 3), (1, 5), (3, 8)}, 1: {(1, 8), (3, 2), (0, 6)}}
    for sx in (1, -1):
        rot = R('Y', math.degrees(ang) * sx)
        m3 = rot.to_3x3()
        mid = Vector((sx * half / 2, 0, z1 + rise - (rise + 0.625) / 2))

        def on_roof(u, y, w):  # u вдоль ската (к карнизу при sx=1), y вдоль конька, w по нормали
            return mid + m3 @ Vector((u, y, w))

        for r in range(nrow):
            for c in range(ncol):
                if (r, c) in holes[sx]:
                    continue
                u, y = -length / 2 + (r + 0.5) * tl, -11 + (c + 0.5) * tw
                h = rng.random()
                top = 'terracotta_05' if h < 0.5 else 'terracotta_06' if h < 0.72 else \
                    'terracotta_03' if h < 0.9 else 'sand_07'
                tr, pos = rot, on_roof(u, y, 0.2)
                if (r, c) in shifted[sx]:
                    tr = rot @ R('X', rng.uniform(-9, 9)) @ R('Y', rng.uniform(-10, 10))
                    pos = on_roof(u + 0.5 * sx, y + rng.uniform(-0.3, 0.3), 0.33)
                shell.box(pos, (tl - 0.08, tw - 0.08, 0.35), by_normal(top, 'terracotta_02'), tr)
        full = [all((r, c) not in holes[sx] for r in range(nrow)) for c in range(ncol)]
        c = 0
        while c < ncol:
            if full[c]:
                e = c
                while e + 1 < ncol and full[e + 1]:
                    e += 1
                colliders.append((on_roof(0, -11 + (c + e + 1) / 2 * tw, 0.2), Vector((length, (e - c + 1) * tw, 0.4)),
                                  rot))
                c = e + 1
            else:
                for r in range(nrow):
                    if (r, c) not in holes[sx]:
                        colliders.append((on_roof(-length / 2 + (r + 0.5) * tl, -11 + (c + 0.5) * tw, 0.2),
                                          Vector((tl, tw, 0.4)), rot))
                c += 1
        if sx == -1:  # стропила и обрешётка под дырой, одно стропило сломано
            for y in (-5.0, -1.0, 1.0):
                shell.box(on_roof(0, y, -0.15), (2 * tl + 1.0, 0.3, 0.3), 'wood_03', rot)
            shell.box(on_roof(tl * 0.5, -3.0, -0.15), (tl + 0.5, 0.3, 0.3), 'wood_03', rot)
            shell.box(on_roof(-tl * 0.6, -3.0, -0.75), (tl, 0.3, 0.3), 'wood_02', rot @ R('Y', 28))
            shell.box(on_roof(0.4, -2.0, -0.45), (0.3, 7.0, 0.3), 'wood_02', rot)
    shell.box((0, 0, z1 + rise + 0.32), (0.8, 22.4, 0.35), 'terracotta_03')
    for k in range(6):  # упавшая черепица: на земле у дыры и на полу внутри
        inside = k >= 4
        pc = Vector((rng.uniform(-5.5, -3.5), rng.uniform(-4.5, -1.5), z0 + 0.1)) if inside else \
            Vector((rng.uniform(-11.2, -9.3), rng.uniform(-5.5, -0.5), 0.1))
        shell.box(pc, (rng.uniform(0.7, 1.3), rng.uniform(0.6, 1.0), 0.18), ('terracotta_05', 'terracotta_03')[k % 2],
                  rnd_rot(rng, 8))

    # покосившийся навес: доски вразнобой, одной нет, одна свисает; одна опора стоит, вторая упала
    awn = R('Y', 7) @ R('X', 14)
    for i in range(5):
        if i == 3:
            continue
        pr = awn @ R('Y', 16) if i == 4 else awn
        pc = Vector((0, -10.95, 9.2)) + awn.to_3x3() @ Vector((-2.24 + 1.12 * i, 0, 0)) - \
            Vector((0, 0, 0.3 if i == 4 else 0))
        shell.box(pc, (1.05, 1.9, 0.22), by_normal(('wood_07', 'wood_05')[i % 2], 'wood_03'), pr)
    shell.box((-2.5, -11.6, 4.6), (0.3, 0.3, 8.5), 'wood_05', R('X', 3))
    shell.box((2.5, -11.6, 1.2), (0.3, 0.3, 1.7), 'wood_05')  # обломок второй опоры
    shell.box((3.6, -13.2, 0.17), (0.3, 0.3, 6.0), 'wood_04', R('Z', 28) @ R('Y', 90))

    cbox((4.5, 4.0, 14.5), (1.6, 1.6, 6.0), 'sand_06')  # труба, колпак съехал
    shell.box((4.6, 4.05, 17.6), (2.0, 2.0, 0.3), 'neutral_03', R('X', 9) @ R('Y', -7))

    # мусор у крыльца: доски, ящик, коробки, банки, покрышка, бумага, осколки под окном
    for c, s, cell, rr in (((-3.6, -12.6, 0.08), (3.0, 0.5, 0.12), 'wood_09', R('Z', 20)),
                           ((2.0, -13.4, 0.08), (2.6, 0.45, 0.12), 'wood_07', R('Z', -35)),
                           ((-1.2, -13.8, 0.2), (2.2, 0.4, 0.12), 'wood_10', R('Z', 70) @ R('Y', 8)),
                           ((-6.2, -11.3, 0.08), (2.4, 0.45, 0.12), 'wood_06', R('Z', 5)),
                           ((4.6, -12.3, 0.45), (1.1, 1.1, 0.9), 'wood_06', R('Z', 15) @ R('X', 6)),
                           ((-4.8, -11.9, 0.3), (0.9, 0.7, 0.6), 'sand_06', R('Z', -10)),
                           ((-2.9, -14.6, 0.03), (1.1, 0.8, 0.05), 'sand_07', R('Z', 40))):
        shell.box(c, s, cell, rr)
    shell.cyl((1.0, -12.9, 0.15), 0.15, 0.35, 6, 'metal_05', 'X')
    shell.cyl((-4.2, -13.2, 0.18), 0.15, 0.36, 6, 'rust_07', 'Z')
    shell.cyl((5.6, -14.2, 0.18), 0.75, 0.35, 8, 'neutral_02', 'Z')
    ground = Plane(lambda a, z: Vector((a, z, 0.0)), (0, 0, 1))
    for c, w, h, cell in (((-0.6, -15.2), 0.6, 0.45, 'neutral_13'), ((3.0, -12.0), 0.5, 0.4, 'sand_13'),
                          ((-5.6, -14.0), 0.55, 0.4, 'neutral_12')):
        ground.put(shell, blob(c, w, h, rng, 5, 0.15), cell, 0.02)
    for k in range(4):
        a, b = rng.uniform(3.6, 6.4), rng.uniform(-10.9, -10.3)
        ground.put(shell, [Vector((a, b)), Vector((a + 0.35, b + 0.1)), Vector((a + 0.1, b + 0.3))],
                   GLASS[k % 2], 0.02)

    # стены: полосы грязи снизу, потёки под окнами и карнизом, отвалившаяся штукатурка (бетон и кирпич)
    planes = {'front': Plane(lambda a, z: Vector((a, -10.0, z)), (0, -1, 0)),
              'back': Plane(lambda a, z: Vector((a, 10.0, z)), (0, 1, 0)),
              'left': Plane(lambda a, z: Vector((-8.0, a, z)), (-1, 0, 0)),
              'right': Plane(lambda a, z: Vector((8.0, a, z)), (1, 0, 0))}
    for wn, spans in (('front', ((-8.0, -2.3), (2.3, 8.0))), ('back', ((-8.0, 8.0),)),
                      ('left', ((-10.0, -1.7), (1.5, 10.0))), ('right', ((-10.0, 10.0),))):
        for a0, a1 in spans:
            planes[wn].put(shell, band(a0, a1, z0, 0.6, 1.4, rng), DIRT, 0.03)
    wins = {'front': front[1:], 'back': back, 'left': side, 'right': side}
    for wn, ws in wins.items():
        for a0, a1, oz0, _ in ws:
            for a in (a0 + 0.4 + rng.uniform(0, 0.4), a1 - 0.5 - rng.uniform(0, 0.4)):
                planes[wn].put(shell, drip((a, oz0 - 0.3), 0.3, rng.uniform(1.2, 2.2), rng), STREAK, 0.04)
    for wn in ('left', 'right'):
        for a in (-8.6, -5.0, -1.8, 2.2, 7.6):
            if wn == 'left' and -2.0 < a < 1.8:
                continue
            planes[wn].put(shell, drip((a + rng.uniform(-0.3, 0.3), z1 - 0.1), 0.45, rng.uniform(1.0, 2.6), rng),
                           STREAK, 0.04)
    peel = (('front', (-7.0, 9.0), 1.6, 1.2), ('front', (2.8, 9.7), 1.4, 0.9), ('front', (7.2, 2.4), 1.2, 1.4),
            ('front', (-2.5, 12.6), 1.6, 1.1), ('back', (-5.0, 9.0), 1.8, 1.2), ('back', (4.5, 2.6), 1.4, 1.2),
            ('left', (-8.0, 9.2), 1.4, 1.2), ('left', (-2.4, 5.4), 1.0, 1.4), ('left', (2.2, 2.0), 1.0, 1.0),
            ('left', (7.6, 2.6), 1.4, 1.2), ('right', (0.0, 8.5), 1.8, 1.4), ('right', (-8.3, 3.0), 1.2, 1.2))
    for wn, c, w, h in peel:
        planes[wn].put(shell, blob(c, w * 1.3, h * 1.2, rng, 9, 0.45), PEEL, 0.045)
        bx, bz = c[0] + rng.uniform(-0.25, 0.25) * w, c[1] + rng.uniform(-0.2, 0.2) * h
        for i in range(rng.randint(2, 4)):  # кирпичи кладки под штукатуркой, рядами со сдвигом
            x, z = bx + (i % 2) * 0.3 - 0.15 + (i // 2) * 0.55 - 0.3, bz + (i % 2) * 0.3 - 0.15
            planes[wn].put(shell, [Vector((x - 0.25, z - 0.12)), Vector((x + 0.25, z - 0.12)),
                                   Vector((x + 0.25, z + 0.12)), Vector((x - 0.25, z + 0.12))], BRICK, 0.06)

    d = Part('Door_1')
    d.box((0, -9.7, (z0 + 8.6) / 2), (3.9, 0.25, 7.95), 'wood_04')
    for y in (-9.92, -9.48):
        d.box((1.45, y, 4.4), (0.2, 0.2, 0.2), 'rust_05')
    dp = Plane(lambda a, z: Vector((a, -9.825, z)), (0, -1, 0))
    dp.put(d, band(-1.9, 1.9, z0 + 0.05, 0.5, 1.1, rng, 0.9), 'wood_02', 0.03)
    dp.put(d, blob((-0.6, 5.6), 1.0, 1.6, rng), 'wood_06', 0.03)

    att = {'Entrance_1': (0, -10.9, 0.35), 'Loot_1': (-5.5, 6.5, z0), 'Loot_2': (5.5, -6.5, z0),
           'Loot_3': (5.0, 7.0, z0), 'ZombieSpawn_1': (-3.0, 4.0, z0), 'SurvivorSpawn_1': (3.0, 2.0, z0)}
    return {
        'name': 'House_Small_01', 'category': 'Buildings', 'primary': 'Shell', 'parts': [shell, d],
        'pivots': {'Door_1': Vector((-1.95, -9.7, (z0 + 8.6) / 2))},
        'attachments': {k: ('Shell', v) for k, v in att.items()}, 'colliders': colliders,
        'studio': {'Shell': {'CanCollide': False, 'CanTouch': False, 'CanQuery': False,
                             'CollisionFidelity': 'Box'},
                   'Door_1': {'CanCollide': True, 'CollisionFidelity': 'Box'}},
    }


# ---------------------------------------------------------------- скала

def rock():
    p = Part('Rock')
    rng = random.Random(7)
    # create_icosphere: subdivisions=1 — икосаэдр (20), 2 — 80, 3 — 320 треугольников
    # крупные грани: 80-гранники, срезанная плоская макушка (пустынная «столовая» скала);
    # цвет — песчаник: горизонтальные слои, пыльная макушка и подножие, без терракоты; у основания мелкие камни
    stones = [(Vector((5.6, 4.4, 4.2)), Vector((0, 0, 0)), 2, 20, False),
              (Vector((2.6, 2.2, 2.2)), Vector((4.8, -3.0, 0)), 2, -35, False),
              (Vector((1.9, 1.6, 1.5)), Vector((-3.6, 3.6, 0)), 2, 10, False),
              (Vector((1.3, 1.2, 1.0)), Vector((-4.6, -3.4, 0)), 2, 60, False)]
    for k in range(9):
        ang = math.radians(rng.uniform(0, 360))
        s = rng.uniform(0.3, 0.75)
        off = Vector((6.4 * math.cos(ang), 5.2 * math.sin(ang), 0)) * rng.uniform(0.95, 1.2)
        stones.append((Vector((s * rng.uniform(1.0, 1.5), s, s * 0.8)), off, 1, rng.uniform(0, 360), True))
    for scale, off, sub, rz, pebble in stones:
        tmp = bmesh.new()
        bmesh.ops.create_icosphere(tmp, subdivisions=sub, radius=1.0)
        rot = Matrix.Rotation(math.radians(rz), 3, 'Z') @ Matrix.Rotation(math.radians(8), 3, 'X')
        for v in tmp.verts:
            k = 1 + rng.uniform(-0.22, 0.22)
            v.co = rot @ Vector((v.co.x * scale.x * k, v.co.y * scale.y * k, v.co.z * scale.z * k))
        minz = min(v.co.z for v in tmp.verts)
        for v in tmp.verts:
            v.co.z -= minz + scale.z * 0.25
        top = max(v.co.z for v in tmp.verts) * 0.82
        for v in tmp.verts:
            v.co.z = min(max(v.co.z, 0.0), top)
            v.co += off
        bmesh.ops.remove_doubles(tmp, verts=tmp.verts[:], dist=0.08 if not pebble else 0.03)
        c = sum((v.co for v in tmp.verts), Vector()) / len(tmp.verts)
        vmap = {v: p.bm.verts.new(v.co) for v in tmp.verts}
        for f in tmp.faces:
            nf = p.bm.faces.new([vmap[v] for v in f.verts])
            orient(nf, c, True)
            h = rng.random()

            def spec(n, fc, h=h, pebble=pebble):
                if pebble:
                    return 'sand_08' if n.z > 0.5 else ('sand_03', 'neutral_07')[h < 0.35]
                if n.z > 0.65:
                    return 'sand_11' if h < 0.7 else 'sand_10'  # пыль на макушке
                if n.z < -0.3:
                    return 'sand_01'  # нависание в тени
                if fc.z < 0.5:
                    return 'sand_09' if h < 0.7 else 'sand_08'  # пыль у подножия
                if h > 0.9:
                    return 'sand_07'
                return ('sand_06', 'sand_04', 'sand_05')[int((fc.z + h * 0.35) / 0.95) % 3]  # слои
            p.pending.append((nf, spec))
        tmp.free()
    bmesh.ops.dissolve_degenerate(p.bm, edges=p.bm.edges[:], dist=0.02)
    p.pending = [(f, s) for f, s in p.pending if f.is_valid]
    return {'name': 'Rock_Desert_01', 'category': 'Nature', 'primary': 'Rock', 'parts': [p],
            'pivots': {}, 'attachments': {}, 'colliders': [],
            'studio': {'Rock': {'CanCollide': True, 'CollisionFidelity': 'Hull'}}}


# ---------------------------------------------------------------- сборка, экспорт

def build(asset, mats, coll):
    report = {'parts': [], 'uv': {}}
    objs = []
    for part in asset['parts']:
        bm = part.finish()
        uvl = bm.loops.layers.uv.new('UVMap')
        name = part.name
        if part.textured:
            island_uv(bm, uvl, part.cell)
            bad, min_px = check_palette_uv(bm, uvl, part.cell)
            report['uv'][name] = {'outside_safe_rect': bad, 'min_px_to_cell_edge': min_px}
        elif name == 'Body':
            report['uv']['Body'] = body_uv(bm, uvl, Vector((0, 0, 2.5)), asset['body_split_z'])
        else:
            box_uv(bm, uvl)
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        tris = len(bm.faces)
        xs, ys, zs = ([v.co[i] for v in bm.verts] for i in range(3))
        lo, hi = Vector((min(xs), min(ys), min(zs))), Vector((max(xs), max(ys), max(zs)))
        bm.free()
        obj = bpy.data.objects.new(name, mesh)
        coll.objects.link(obj)
        mat = mats['paint'] if name in ('Body', 'Hood', 'Trunk') else \
            mats['collider'] if name == 'Collider' else mats['glass'] if name == 'Glass' else mats['palette']
        mesh.materials.append(mat)
        if name == 'Collider':
            obj.display_type = 'WIRE'
            obj.hide_render = True
        objs.append(obj)
        center = (lo + hi) / 2
        entry = {'name': name, 'tris': tris, 'size': size_rbx(hi - lo), 'center': to_rbx(center),
                 'textured': part.textured}
        if name in asset['pivots']:
            entry['pivot_offset'] = to_rbx(asset['pivots'][name] - center)
        report['parts'].append(entry)
    visible = sum(p['tris'] for p in report['parts'] if p['name'] != 'Collider')
    manifest = {
        'asset': asset['name'], 'category': asset['category'], 'primary_part': asset['primary'],
        'coords': 'Roblox studs; pivot модели = центр основания (0,0,0); перёд −Z; оси (x,y,z)_blender → (−x,z,y)',
        'attributes': {'AssetId': asset['name'], 'Category': asset['category'], 'Tris': visible,
                       **asset.get('attributes', {})},
        'tris_visible': visible, 'parts': report['parts'],
        # pivot модели (= pivot PrimaryPart): центр основания, у варианта колеса — ось
        'model_pivot': to_rbx(asset.get('model_pivot', Vector((0, 0, 0)))),
        'attachments': [{'name': k, 'parent': par, 'position': to_rbx(v)}
                        for k, (par, v) in asset['attachments'].items()],
        'colliders': [{'center': to_rbx(c), 'size': size_rbx(s),
                       'rot': [round(x, 5) for row in (P @ (r.to_3x3() if r else Matrix.Identity(3)) @ P.transposed())
                               for x in row]}
                      for c, s, r in asset['colliders']],
        'studio_props': asset['studio'], 'uv': report['uv'],
        'palette_image_id': '75482071682779 (T_Palette_Main, группа «Грева нет» 867558223)',
    }
    return objs, manifest


def export(objs, name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        if o.name != 'Collider':
            o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.wm.obj_export(filepath=str(OUT / f'{name}.obj'), export_selected_objects=True,
                          forward_axis='NEGATIVE_Z', up_axis='Y', export_triangulated_mesh=True,
                          export_normals=True, export_uv=True, export_materials=True, path_mode='STRIP',
                          export_smooth_groups=False, export_object_groups=True)
    bpy.ops.export_scene.fbx(filepath=str(OUT / f'{name}.fbx'), use_selection=True, global_scale=0.01,
                             apply_unit_scale=True, apply_scale_options='FBX_SCALE_ALL', axis_forward='-Z',
                             axis_up='Y', object_types={'MESH'}, mesh_smooth_type='FACE', use_triangles=True,
                             path_mode='STRIP', bake_space_transform=True)


# ---------------------------------------------------------------- превью

def r15_dummy(coll, at, mats):
    m = bpy.data.materials.new('R15_Dummy')
    m.diffuse_color = (0.35, 0.45, 0.75, 1)
    parts = [((0, 0, 1.0), (0.95, 0.95, 2.0), -0.5), ((0, 0, 1.0), (0.95, 0.95, 2.0), 0.5),
             ((0, 0, 3.0), (2.0, 1.0, 2.0), 0), ((0, 0, 3.0), (0.95, 0.95, 2.0), -1.5),
             ((0, 0, 3.0), (0.95, 0.95, 2.0), 1.5), ((0, 0, 4.6), (1.2, 1.2, 1.2), 0)]
    bm = bmesh.new()
    for c, s, dx in parts:
        g = bmesh.ops.create_cube(bm, size=1.0)
        for v in g['verts']:
            v.co = Vector((v.co.x * s[0] + c[0] + dx, v.co.y * s[1] + c[1], v.co.z * s[2] + c[2]))
    mesh = bpy.data.meshes.new('R15')
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(m)
    o = bpy.data.objects.new('R15_Dummy', mesh)
    o.location = at
    coll.objects.link(o)
    return o


def look(cam, eye, target):
    cam.location = eye
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat('-Z', 'Y').to_euler()


def render_previews(groups, mats):
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_WORKBENCH'
    sh = sc.display.shading
    sh.light = 'STUDIO'
    try:
        sh.studio_light = 'outdoor.sl'
    except TypeError:
        pass
    sh.color_type = 'TEXTURE'
    sh.show_shadows = True
    sh.shadow_intensity = 0.45
    sh.show_cavity = False
    sc.display.light_direction = (0.45, -0.35, 0.82)
    sc.view_settings.view_transform = 'Standard'  # AgX глушит плоские цвета палитры
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    sc.render.film_transparent = False
    if sc.world is None:
        sc.world = bpy.data.worlds.new('World')
    sc.world.color = (0.62, 0.74, 0.86)
    prev = bpy.data.collections.new('Preview')
    sc.collection.children.link(prev)
    gm = bpy.data.materials.new('Ground')
    gm.diffuse_color = (0.86, 0.74, 0.55, 1)
    bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, -0.01))
    ground = bpy.context.active_object
    ground.data.materials.append(gm)
    offsets = {'House_Small_01': Vector((0, 0, 0)), 'Sedan': Vector((19, -6, 0)),
               'Rock_Desert_01': Vector((-19, -4, 0)), 'Sedan_Wheel_Flat': Vector((25, -16, 0))}
    for name, objs in groups.items():
        for o in objs:
            o.location = offsets[name]
    for p in (Vector((-3.5, -15, 0)), Vector((14.5, -8.5, 0)), Vector((-13, -10, 0))):
        r15_dummy(prev, p, mats)
    cam_data = bpy.data.cameras.new('Cam')
    cam = bpy.data.objects.new('Cam', cam_data)
    prev.objects.link(cam)
    sc.camera = cam
    pv = OUT / 'preview'
    pv.mkdir(parents=True, exist_ok=True)
    shots = {
        'lineup': ((4, -78, 30), (0, -3, 4), 42),
        'house': ((-22, -36, 14), (0, -2, 6), 45),
        'sedan': ((32, -24, 9), (19, -6, 2.5), 40),
        'sedan_rear': ((8, 10, 8), (19, -6, 2.5), 40),
        'rock': ((-34, -22, 9), (-19, -4, 2.5), 40),
        'first_person': ((-3.5, -22, 4.6), (0, -2, 5), 70),
        'third_person': ((-5, -27, 9), (-3.5, -15, 4), 60),
    }
    for nm, (eye, tgt, fov) in shots.items():
        cam_data.angle = math.radians(fov)
        look(cam, eye, tgt)
        sc.render.filepath = str(pv / f'{nm}.png')
        bpy.ops.render.render(write_still=True)
    # демо краски: в игре Body.Color задаёт сервер; в .rbxm Body белый
    mats['paint'].diffuse_color = (0.65, 0.26, 0.21, 1)
    cam_data.angle = math.radians(40)
    look(cam, *shots['sedan'][:2])
    sc.render.filepath = str(pv / 'sedan_paint_demo.png')
    bpy.ops.render.render(write_still=True)
    mats['paint'].diffuse_color = (1, 1, 1, 1)


def uv_layout(obj, path, n=1024):
    """Схема UV для художника скинов: рёбра треугольников на белом (uv.export_layout без GPU не работает)."""
    px = [1.0] * (n * n * 4)
    me = obj.data
    uv = me.uv_layers.active.data

    def dot(x, y):
        if 0 <= x < n and 0 <= y < n:
            i = (y * n + x) * 4
            px[i] = px[i + 1] = 0.15
            px[i + 2] = 0.55

    for poly in me.polygons:
        pts = [uv[i].uv for i in poly.loop_indices]
        for a, b in zip(pts, pts[1:] + pts[:1]):
            x0, y0, x1, y1 = a.x * n, a.y * n, b.x * n, b.y * n
            steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
            for s in range(steps + 1):
                t = s / steps
                dot(int(x0 + (x1 - x0) * t), int(y0 + (y1 - y0) * t))
    img = bpy.data.images.new('Body_UV', n, n)
    img.pixels = px
    img.filepath_raw = str(path)
    img.file_format = 'PNG'
    img.save()


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    OUT.mkdir(parents=True, exist_ok=True)
    mats = materials()
    groups, summary = {}, {}
    for fn in (house, sedan, rock, sedan_wheel_flat):
        asset = fn()
        coll = bpy.data.collections.new(asset['name'])
        bpy.context.scene.collection.children.link(coll)
        objs, manifest = build(asset, mats, coll)
        export(objs, asset['name'])
        (OUT / f"{asset['name']}.manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=1), encoding='utf-8')
        groups[asset['name']] = objs
        summary[asset['name']] = {p['name']: p['tris'] for p in manifest['parts']}
        summary[asset['name']]['_visible'] = manifest['tris_visible']
        summary[asset['name']]['_uv'] = {k: v for k, v in manifest['uv'].items() if 'groups' not in v}
    tpl = (Path(__file__).parent / 'assemble_template.luau').read_text(encoding='utf-8')
    data = json.dumps([json.loads((OUT / f'{n}.manifest.json').read_text(encoding='utf-8')) for n in groups],
                      ensure_ascii=False)
    (Path(__file__).parent / 'assemble_style_test.luau').write_text(
        tpl.replace('--@@MANIFESTS@@', data), encoding='utf-8')
    vtpl = (Path(__file__).parent / 'verify_template.luau').read_text(encoding='utf-8')
    (Path(__file__).parent / 'verify_style_test.luau').write_text(
        vtpl.replace('--@@MANIFESTS@@', data), encoding='utf-8')
    body = next(o for o in groups['Sedan'] if o.name == 'Body')
    uv_layout(body, OUT / 'Sedan_Body_UV.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'StyleTest.blend'), compress=True)
    render_previews(groups, mats)
    print('STYLE_TEST_SUMMARY ' + json.dumps(summary, ensure_ascii=False))


main()
