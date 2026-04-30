#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-two-png
# @title: pngquant --speed 2
# @description: Quantizes basn2c08.png with --speed 2 (slow, high quality side of the trade-off) to 16 colors and verifies the result is a valid 32x32 PNG with at most 16 unique colors.
# @timeout: 240
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-speed-two-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --force --speed 2 --output "$tmpdir/out.png" 16 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'

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
_ = int(tok())
if (w, h) != (32, 32):
    raise SystemExit(f'unexpected dims {w}x{h}')
if data[idx] in b' \t\r\n':
    idx += 1
payload = data[idx:]
if len(payload) != 32 * 32 * 3:
    raise SystemExit('short payload')
colors = {payload[i:i + 3] for i in range(0, len(payload), 3)}
if len(colors) > 16:
    raise SystemExit(f'expected <=16 colors, got {len(colors)}')
PY
