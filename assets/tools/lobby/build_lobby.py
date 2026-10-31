"""Лобби P0 (ASSETS_PROMPT §7): двор-перевалочный пункт выживших и трое ворот — Город, Море, Горы.

Запуск (Blender 5.2+):
  blender --background --factory-startup --python assets/tools/lobby/build_lobby.py

Геометрия, UV на палитру, экспорт и манифесты — общие с style test (assets/tools/style_test/build_style_test.py).
Выход: assets/source/lobby/ — <Asset>.obj/.mtl/.fbx/.manifest.json, Lobby_All.obj (один импорт в Studio),
Lobby.blend, preview/*.png; assets/tools/lobby/assemble_lobby.luau и verify_lobby.luau.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(HERE.parent / 'style_test')]

import build_style_test as bst  # noqa: E402
import lobby_doors  # noqa: E402
import lobby_hub  # noqa: E402
from merge_obj import merge  # noqa: E402

OUT = bst.ASSETS / 'source' / 'lobby'
bst.OUT = OUT  # export() пишет в bst.OUT
PLACE = Vector((0, 0, 300))  # где собрать лобби в тестовом плейсе (Roblox), подальше от style test


def assets():
    gates = [lobby_doors.gate(r, r == 'City') for r in ('Sea', 'City', 'Mountains')]
    return [lobby_hub.hub()] + gates


def manifest_fix(m, asset):
    """Части <Ворота>__<Часть> → имя по контракту + src (имя группы в OBJ); место сборки в Studio."""
    for p in m['parts']:
        if '__' in p['name']:
            p['src'], p['name'] = p['name'], p['name'].split('__', 1)[1]
    if asset['name'] == 'Lobby_Hub':
        m['place_at'] = list(PLACE)
    else:
        x = lobby_hub.GATES[asset['attributes']['Region']]
        m['place_at'] = [PLACE.x - x, PLACE.y, PLACE.z + lobby_hub.HY]  # DoorSlot в координатах Roblox
    return m


def previews(groups):
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_WORKBENCH'
    sh = sc.display.shading
    sh.light, sh.color_type, sh.show_shadows, sh.shadow_intensity = 'STUDIO', 'TEXTURE', True, 0.45
    try:
        sh.studio_light = 'outdoor.sl'
    except TypeError:
        pass
    sc.display.light_direction = (0.45, -0.35, 0.82)
    sc.view_settings.view_transform = 'Standard'
    sc.render.resolution_x, sc.render.resolution_y = 1600, 900
    if sc.world is None:
        sc.world = bpy.data.worlds.new('World')
    sc.world.color = (0.62, 0.74, 0.86)
    prev = bpy.data.collections.new('Preview')
    sc.collection.children.link(prev)
    for name, objs in groups.items():
        if name == 'Lobby_Hub':
            continue
        x = lobby_hub.GATES[name.rsplit('_', 1)[1]]
        for o in objs:
            o.location = (x, lobby_hub.HY, 0)
        if name.endswith('City'):  # открытые ворота: створка повёрнута на петле, замка нет
            for o in objs:
                if o.name.endswith('__Door'):
                    hinge = Vector((x - lobby_doors.GATE_W / 2, lobby_hub.HY, 0))
                    o.matrix_world = (Matrix.Translation(hinge) @ Matrix.Rotation(math.radians(100), 4, 'Z')
                                      @ Matrix.Translation(-hinge) @ o.matrix_world)
                if o.name.endswith('__Lock'):
                    o.hide_render = True
    for p in ((-6, -28, 0), (4, -24, 0), (-14, -10, 0)):
        bst.r15_dummy(prev, Vector(p), None)
    cam_data = bpy.data.cameras.new('Cam')
    cam = bpy.data.objects.new('Cam', cam_data)
    prev.objects.link(cam)
    sc.camera = cam
    pv = OUT / 'preview'
    pv.mkdir(parents=True, exist_ok=True)
    shots = {
        'overview': ((0, -95, 70), (0, 0, 0), 50),
        'spawn_view': ((0, -34, 5), (0, 40, 7), 70),
        'gates': ((0, 12, 6), (0, 40, 9), 75),
        'campfire': ((-10, -16, 6), (0, -4, 1.5), 55),
        'tower': ((20, 10, 10), (40, 32, 12), 55),
    }
    for nm, (eye, tgt, fov) in shots.items():
        cam_data.angle = math.radians(fov)
        bst.look(cam, eye, tgt)
        sc.render.filepath = str(pv / f'{nm}.png')
        bpy.ops.render.render(write_still=True)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    OUT.mkdir(parents=True, exist_ok=True)
    mats = bst.materials()
    groups, manifests, summary = {}, [], {}
    for asset in assets():
        coll = bpy.data.collections.new(asset['name'])
        bpy.context.scene.collection.children.link(coll)
        objs, m = bst.build(asset, mats, coll)
        bst.export(objs, asset['name'])
        m = manifest_fix(m, asset)
        (OUT / f"{asset['name']}.manifest.json").write_text(json.dumps(m, ensure_ascii=False, indent=1), encoding='utf-8')
        groups[asset['name']] = objs
        manifests.append(m)
        summary[asset['name']] = {p['name']: p['tris'] for p in m['parts']}
        summary[asset['name']]['_visible'] = m['tris_visible']
        summary[asset['name']]['_uv_bad'] = sum(v.get('outside_safe_rect', 0) for v in m['uv'].values())
    merge(OUT, list(groups), 'Lobby_All')
    data = json.dumps(manifests, ensure_ascii=False)
    st = HERE.parent / 'style_test'
    (HERE / 'assemble_lobby.luau').write_text(
        (st / 'assemble_template.luau').read_text(encoding='utf-8').replace('--@@MANIFESTS@@', data)
        .replace('"StyleTest"', '"Lobby"'), encoding='utf-8')
    (HERE / 'verify_lobby.luau').write_text(
        (st / 'verify_template.luau').read_text(encoding='utf-8').replace('--@@MANIFESTS@@', data)
        .replace('workspace.StyleTest', 'workspace.Lobby'), encoding='utf-8')
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'Lobby.blend'), compress=True)
    previews(groups)
    print('LOBBY_SUMMARY ' + json.dumps(summary, ensure_ascii=False))


main()
