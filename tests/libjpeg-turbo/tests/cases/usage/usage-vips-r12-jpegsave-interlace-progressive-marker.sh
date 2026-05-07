#!/usr/bin/env bash
# @testcase: usage-vips-r12-jpegsave-interlace-progressive-marker
# @title: vips jpegsave --interlace writes an SOF2 progressive marker
# @description: Saves a JPEG via vips jpegsave with --interlace and confirms the byte stream contains the SOF2 (FFC2) progressive start-of-frame marker rather than the SOF0 (FFC0) baseline marker.
# @timeout: 60
# @tags: usage, jpeg, image, progressive
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
w, h = 48, 36
data = bytes([(((x * 7) ^ (y * 5)) & 0xff)
              for y in range(h) for x in range(w * 3)])
open(sys.argv[1], 'wb').write(f'P6\n{w} {h}\n255\n'.encode() + data)
PY

vips jpegsave "$tmpdir/in.ppm" "$tmpdir/prog.jpg" --interlace --Q 80

python3 - "$tmpdir/prog.jpg" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:2] == b"\xff\xd8", data[:2].hex()
assert b"\xff\xc2" in data, "missing SOF2 (progressive) marker"
assert b"\xff\xc0" not in data, "unexpected SOF0 (baseline) marker"
PY
