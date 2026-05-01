#!/usr/bin/env bash
# @testcase: usage-vipsthumbnail-linear-jpeg
# @title: vipsthumbnail --linear JPEG output
# @description: Generates a JPEG thumbnail with vipsthumbnail --linear (linear-light shrink) at a 16-pixel size and confirms the output is a JPEG whose long edge equals 16, exercising libjpeg-turbo's decode + re-encode through the linear pipeline.
# @timeout: 180
# @tags: usage, jpeg, image, thumbnail
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
from pathlib import Path
W, H = 64, 48
pixels = bytearray()
for y in range(H):
    for x in range(W):
        pixels += bytes((((x * 7) ^ (y * 5)) & 255, (x * 4) & 255, (y * 4) & 255))
Path(sys.argv[1]).write_bytes(f"P6\n{W} {H}\n255\n".encode() + bytes(pixels))
PY

cjpeg "$tmpdir/in.ppm" >"$tmpdir/in.jpg"

# vipsthumbnail writes <basename>.jpg next to the requested -o pattern.
( cd "$tmpdir" && vipsthumbnail in.jpg --linear --size 16x16 -o 'thumb-%s.jpg' )
test -f "$tmpdir/thumb-in.jpg"
file "$tmpdir/thumb-in.jpg" | tee "$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'JPEG image data'

vipsheader "$tmpdir/thumb-in.jpg" | tee "$tmpdir/header.out"

python3 - <<'PY' "$tmpdir/header.out"
import sys
from pathlib import Path
line = Path(sys.argv[1]).read_text().strip()
parts = line.split()
dims = next(p for p in parts if 'x' in p and p.split('x')[0].isdigit())
w, h = (int(v) for v in dims.split('x')[:2])
assert max(w, h) == 16, f'expected long edge 16, got {w}x{h}'
# Source aspect was 64x48 (4:3); shrink to fit-inside 16x16 must preserve it.
assert (w, h) == (16, 12), f'expected 16x12 fit, got {w}x{h}'
print('linear thumbnail', w, 'x', h)
PY
