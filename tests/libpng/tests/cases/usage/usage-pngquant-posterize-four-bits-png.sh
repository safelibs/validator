#!/usr/bin/env bash
# @testcase: usage-pngquant-posterize-four-bits-png
# @title: pngquant --posterize 4 caps per-channel range
# @description: Posterizes basn2c08.png with --posterize 4 (4 bits per channel) and confirms the decoded output has at most 16 distinct values per RGB channel while still containing more than 1 value, exercising a posterization bit-depth not used by the existing 1/2/3 cases.
# @timeout: 180
# @tags: usage, image, png, quantization
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --posterize 4 --force --output "$tmpdir/out.png" 256 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
pngtopnm "$png" >"$tmpdir/in.ppm"

python3 - "$tmpdir/out.ppm" "$tmpdir/in.ppm" <<'PY'
import sys

def parse_p6(path):
    data = open(path, 'rb').read()
    idx = 0
    def skip_ws():
        nonlocal idx
        while idx < len(data):
            b = data[idx]
            if b in b' \t\r\n':
                idx += 1
                continue
            if b == 35:
                while idx < len(data) and data[idx] not in (10, 13):
                    idx += 1
                continue
            break
    def tok():
        nonlocal idx
        skip_ws()
        s = idx
        while idx < len(data) and data[idx] not in b' \t\r\n':
            idx += 1
        return data[s:idx]
    if tok() != b'P6':
        raise SystemExit('not P6')
    w = int(tok()); h = int(tok()); maxv = int(tok())
    if data[idx] in b' \t\r\n':
        idx += 1
    return w, h, maxv, data[idx:]

w_o, h_o, mv_o, body_o = parse_p6(sys.argv[1])
w_i, h_i, mv_i, body_i = parse_p6(sys.argv[2])
if (w_o, h_o, mv_o) != (32, 32, 255):
    raise SystemExit(f'unexpected output {w_o}x{h_o}@{mv_o}')

distinct = [set(), set(), set()]
for i in range(0, len(body_o), 3):
    for c in range(3):
        distinct[c].add(body_o[i + c])
sizes = [len(s) for s in distinct]
print(f'distinct per-channel: {sizes}')
for c, s in enumerate(distinct):
    if len(s) < 2:
        raise SystemExit(f'channel {c} collapsed to {len(s)} values - posterize 4 should preserve some variation on a gradient')
    if len(s) > 16:
        raise SystemExit(f'channel {c} has {len(s)} distinct values - --posterize 4 should cap at 16')
PY
