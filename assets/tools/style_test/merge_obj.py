"""Склеивает OBJ style test в один файл для одного импорта в Studio (File → Import 3D).

python assets/tools/style_test/merge_obj.py
Имена частей во всех ассетах разные, поэтому assemble_style_test.luau находит их и в общей модели.
Функцию merge() использует и assets/tools/lobby/build_lobby.py.
"""
import shutil
from pathlib import Path

SRC = Path(__file__).resolve().parents[2] / 'source' / 'style_test'
NAMES = ['House_Small_01', 'Sedan', 'Rock_Desert_01', 'Sedan_Wheel_Flat']


def normalize_groups(path):
    """Отдельный OBJ из Blender: группы <объект>_<меш> → имя части (как в merge), чтобы импорт дал верные имена."""
    out = []
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        if line.startswith(('g ', 'o ')):
            name_ = line[2:].strip()
            half = name_[:len(name_) // 2]
            line = f'{line[0]} {half if name_ == f"{half}_{half}" else name_}'
        out.append(line)
    Path(path).write_text('\n'.join(out) + '\n', encoding='utf-8')


def merge(src=SRC, names=NAMES, out_name='StyleTest_All'):
    out, mtl, seen = [f'# {out_name}: ' + ', '.join(names), f'mtllib {out_name}.mtl'], [], set()
    off = {'v': 0, 'vt': 0, 'vn': 0}
    for name in names:
        cnt = {'v': 0, 'vt': 0, 'vn': 0}
        for line in (src / f'{name}.obj').read_text(encoding='utf-8').splitlines():
            tag = line.split(' ', 1)[0]
            if tag in cnt:
                cnt[tag] += 1
                out.append(line)
            elif tag == 'f':
                parts = []
                for item in line.split()[1:]:
                    idx = item.split('/')
                    for k, key in enumerate(('v', 'vt', 'vn')):
                        if k < len(idx) and idx[k]:
                            idx[k] = str(int(idx[k]) + off[key])
                    parts.append('/'.join(idx))
                out.append('f ' + ' '.join(parts))
            elif tag in ('o', 'g'):
                # импортёр Studio делит OBJ на MeshPart по группам g, а не по объектам o;
                # Blender пишет группы как <объект>_<меш> — оставляем имя части
                name_ = line[2:].strip()
                half = name_[:len(name_) // 2]
                if name_ == f'{half}_{half}':
                    name_ = half
                if not out[-1].startswith('g '):
                    out += [f'o {name_}', f'g {name_}']
            elif tag in ('usemtl', 's'):
                out.append(line)
        for key in off:
            off[key] += cnt[key]
        block = None
        for line in (src / f'{name}.mtl').read_text(encoding='utf-8').splitlines():
            if line.startswith('newmtl '):
                block = line[7:] if line[7:] not in seen else None
                if block:
                    seen.add(block)
            if block:
                mtl.append(line)
    # импортёр Studio ищет map_Kd рядом с .mtl и без файла даёт ошибку на каждой палитровой части;
    # с файлом он ещё и загружает палитру от выбранного Creator (группы)
    shutil.copyfile(Path(__file__).resolve().parents[2] / 'textures' / 'models' / 'T_Palette_Main.png',
                    src / 'T_Palette_Main.png')
    (src / f'{out_name}.obj').write_text('\n'.join(out) + '\n', encoding='utf-8')
    (src / f'{out_name}.mtl').write_text('\n'.join(mtl) + '\n', encoding='utf-8')
    print(src / f'{out_name}.obj', off)


if __name__ == '__main__':
    merge()
