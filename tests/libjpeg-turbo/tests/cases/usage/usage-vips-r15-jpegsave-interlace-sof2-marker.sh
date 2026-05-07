#!/usr/bin/env bash
# @testcase: usage-vips-r15-jpegsave-interlace-sof2-marker
# @title: vips jpegsave --interlace emits a JPEG carrying an SOF2 (FFC2) progressive marker
# @description: Saves a JPEG via vips jpegsave with --interlace and confirms the output stream contains the FFC2 SOF2 marker, exercising libjpeg-turbo's progressive Huffman encoder path through vips.
# @timeout: 180
# @tags: usage, jpeg, image, interlace
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
w, h = 56, 40
data = bytes([(((x * 7) ^ (y * 13)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/inter.jpg" --interlace --Q 80
file "$tmpdir/inter.jpg" | grep -q 'JPEG image data'

python3 - <<'PY' "$tmpdir/inter.jpg"
import sys
from pathlib import Path
data = Path(sys.argv[1]).read_bytes()
assert data[:2] == b'\xff\xd8' and data[-2:] == b'\xff\xd9', 'invalid JPEG'
assert b'\xff\xc2' in data, 'missing SOF2 marker for --interlace'
PY
