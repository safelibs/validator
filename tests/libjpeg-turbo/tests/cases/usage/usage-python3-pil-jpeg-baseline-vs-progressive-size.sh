#!/usr/bin/env bash
# @testcase: usage-python3-pil-jpeg-baseline-vs-progressive-size
# @title: Pillow baseline vs progressive JPEG SOF marker
# @description: Saves the same image as baseline and progressive JPEG via Pillow and confirms the SOF0 marker appears for baseline and SOF2 for progressive.
# @timeout: 180
# @tags: usage, jpeg, python, encoder
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

tmpdir = Path(sys.argv[1])
src = Image.new('RGB', (24, 24))
src.putdata([((x * 11) % 256, (y * 13) % 256, ((x ^ y) * 5) % 256)
             for y in range(24) for x in range(24)])

base = tmpdir / 'base.jpg'
prog = tmpdir / 'prog.jpg'
src.save(base, 'JPEG', quality=85, progressive=False)
src.save(prog, 'JPEG', quality=85, progressive=True)

base_bytes = base.read_bytes()
prog_bytes = prog.read_bytes()

# SOF0 = FFC0 (baseline), SOF2 = FFC2 (progressive). Exactly one should
# appear in each stream.
assert b'\xff\xc0' in base_bytes and b'\xff\xc2' not in base_bytes, 'baseline missing SOF0'
assert b'\xff\xc2' in prog_bytes and b'\xff\xc0' not in prog_bytes, 'progressive missing SOF2'
print('baseline=SOF0 progressive=SOF2')
PYCASE
