#!/usr/bin/env bash
# @testcase: usage-netpbm-r20-pngtopnm-rgb-png-yields-ppm
# @title: netpbm pngtopnm on an RGB PNG emits a P6 PPM of matching dimensions
# @description: Encodes a 14x9 RGB PPM via pnmtopng, decodes the result back through pngtopnm, and asserts the decoded output begins with the P6 magic and reports the same WxH dimensions, exercising libpng's decode path through netpbm's pngtopnm tool.
# @timeout: 120
# @tags: usage, png, netpbm, pngtopnm, rgb, r20
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 14, 9
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 11) & 0xff, (y * 13) & 0xff, ((x + y) * 3) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

pnmtopng "$tmpdir/in.ppm" >"$tmpdir/mid.png"
pngtopnm "$tmpdir/mid.png" >"$tmpdir/out.ppm"

python3 - "$tmpdir/out.ppm" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert data[:2] == b'P6', data[:2]
# read text header WxH
i = 3
def take_token():
    global i
    while data[i:i+1] in (b' ', b'\n', b'\t', b'\r'):
        i += 1
    j = i
    while data[j:j+1] not in (b' ', b'\n', b'\t', b'\r'):
        j += 1
    tok = data[i:j].decode()
    i = j
    return tok
# skip optional comments
def skip_ws_and_comments():
    global i
    while True:
        while data[i:i+1] in (b' ', b'\n', b'\t', b'\r'):
            i += 1
        if data[i:i+1] == b'#':
            while data[i:i+1] != b'\n':
                i += 1
        else:
            break
skip_ws_and_comments()
w = int(take_token())
skip_ws_and_comments()
h = int(take_token())
assert (w, h) == (14, 9), (w, h)
PY
