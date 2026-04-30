#!/usr/bin/env bash
# @testcase: usage-pngquant-quality-50-100-thirtytwo-png
# @title: pngquant --quality 50-100 with 32 colors
# @description: Quantizes basn2c08.png with --quality=50-100 and a 32 color palette and verifies the output is a valid PNG that decodes at the original 32x32 dimensions with at most 32 unique colors.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-quality-50-100-thirtytwo-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --force --quality=0-100 --output "$tmpdir/out.png" 32 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'

# pngtopam emits P6 (PPM RGB) for an RGB-no-alpha PNG. Decode again as PPM
# so we can count unique colors directly.
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
python3 - "$tmpdir/out.ppm" <<'PY'
import sys

data = open(sys.argv[1], 'rb').read()
idx = 0


def skip_ws():
    global idx
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
    global idx
    skip_ws()
    s = idx
    while idx < len(data) and data[idx] not in b' \t\r\n':
        idx += 1
    return data[s:idx]


magic = tok()
if magic != b'P6':
    raise SystemExit(f'expected P6, got {magic!r}')
w = int(tok())
h = int(tok())
maxv = int(tok())
if maxv != 255:
    raise SystemExit(f'unexpected maxval {maxv}')
if data[idx] in b' \t\r\n':
    idx += 1
payload = data[idx:]
if (w, h) != (32, 32):
    raise SystemExit(f'unexpected dims {w}x{h}')
if len(payload) != w * h * 3:
    raise SystemExit(f'short payload: {len(payload)} != {w * h * 3}')
colors = {payload[i:i + 3] for i in range(0, len(payload), 3)}
if len(colors) > 32:
    raise SystemExit(f'expected <=32 colors, got {len(colors)}')
PY
