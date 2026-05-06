#!/usr/bin/env bash
# @testcase: usage-netpbm-r10-pamhue-shift-png
# @title: netpbm pamhue 120-degree rotation maps red to green
# @description: Decodes a pure-red PNG, rotates the hue by 120 degrees with pamhue, and verifies the result is dominated by the green channel.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'P3\n1 1\n255\n255 0 0\n' >"$tmpdir/red.ppm"
pnmtopng "$tmpdir/red.ppm" >"$tmpdir/red.png"

pngtopnm "$tmpdir/red.png" | pamhue -huechange=120 >"$tmpdir/shifted.ppm"

python3 - "$tmpdir/shifted.ppm" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
header_end = 0
nl = 0
for i, byte in enumerate(data):
    if byte == 0x0a:
        nl += 1
        if nl == 3:
            header_end = i + 1
            break
r, g, b = data[header_end], data[header_end + 1], data[header_end + 2]
assert g > 200, (r, g, b)
assert r < 60, (r, g, b)
assert b < 60, (r, g, b)
PY
