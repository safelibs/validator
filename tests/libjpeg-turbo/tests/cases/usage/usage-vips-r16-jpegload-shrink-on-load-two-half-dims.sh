#!/usr/bin/env bash
# @testcase: usage-vips-r16-jpegload-shrink-on-load-two-half-dims
# @title: vips jpegload --shrink 2 halves a 80x40 JPEG to 40x20 via DCT-domain shrink
# @description: Encodes a generated 80x40 RGB image through vips jpegsave, decodes via vips jpegload --shrink 2, and asserts the resulting image is reported as 40x20 in vipsheader, exercising libjpeg-turbo's shrink-on-load DCT decoder.
# @timeout: 180
# @tags: usage, vips, jpeg, shrink
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 80, 40
data = bytes([(((x * 5) ^ (y * 9)) & 0xff)
              for y in range(H) for x in range(W * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/in.jpg" --Q 85
vips jpegload "$tmpdir/in.jpg" "$tmpdir/out.v" --shrink 2

vipsheader "$tmpdir/out.v" >"$tmpdir/hdr.out"
python3 - "$tmpdir/hdr.out" <<'PY'
import sys, pathlib
line = pathlib.Path(sys.argv[1]).read_text().strip()
dims = next(p for p in line.split() if 'x' in p and p.split('x')[0].isdigit())
w, h = (int(v) for v in dims.split('x')[:2])
assert (w, h) == (40, 20), f"expected 40x20, got {w}x{h}"
PY
