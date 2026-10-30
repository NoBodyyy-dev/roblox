"""Rebuild TEST_01 twice and compare hashes and pixels with checkout baseline."""
import hashlib
import io
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

assets = Path(__file__).resolve().parent.parent
textures = assets / 'textures/models'
tests = textures / '_tests'
tests.mkdir(exist_ok=True)
repo = assets.parent
def git_bytes(p):
    return subprocess.check_output(['git', 'show', f'HEAD:{p.relative_to(repo).as_posix()}'], cwd=repo)
baseline = {p.relative_to(assets).as_posix(): git_bytes(p)
            for p in [*textures.glob('*.png'), assets / 'palette/palette.json',
                      *assets.joinpath('source/test').glob('*.obj')]}
original_info = json.loads(git_bytes(textures / '_build_info.json'))
snapshots = []
for run in (1, 2):
    result = subprocess.run([sys.executable, '-X', 'utf8', str(assets / 'tools/gen_palette.py')],
                            capture_output=True, text=True, encoding='utf-8')
    log = '\n'.join(line.rstrip() for line in (result.stdout + result.stderr).splitlines()) + '\n'
    (tests / f'rebuild_run_{run}.txt').write_text(log, encoding='utf-8')
    if result.returncode:
        raise SystemExit(f'Generator run {run} failed: see rebuild_run_{run}.txt')
    paths = [assets / name for name in baseline] + [textures / '_build_info.json', textures / '_selfcheck_palette.txt']
    snapshots.append({p.relative_to(assets).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})
    print(f'Run {run} finished', flush=True)

checks = []
for name, data in baseline.items():
    p = assets / name
    row = {'file': name, 'bytes': p.stat().st_size, 'baseline_bytes_equal': data == p.read_bytes()}
    if p.suffix == '.png':
        before = Image.open(io.BytesIO(data))
        after = Image.open(p)
        row.update(size=list(after.size), mode=after.mode,
                   pixels_equal=before.mode == after.mode and np.array_equal(np.asarray(before), np.asarray(after)))
    checks.append(row)
evidence = {'baseline_build_info': original_info,
            'windows_build_info': json.loads((textures / '_build_info.json').read_text()),
            'two_runs_all_hashes_equal': snapshots[0] == snapshots[1],
            'run_hashes': snapshots, 'files': checks}
(tests / 'rebuild_evidence.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'two_runs_all_hashes_equal': evidence['two_runs_all_hashes_equal'],
                  'pixel_mismatches': [c['file'] for c in checks if c.get('pixels_equal') is False]}, ensure_ascii=False), flush=True)
if snapshots[0] != snapshots[1] or any(c.get('pixels_equal') is False for c in checks):
    raise SystemExit('STOP: rebuild mismatch')
