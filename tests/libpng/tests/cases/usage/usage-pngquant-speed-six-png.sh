#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-six-png
# @title: pngquant --speed 6 mid setting
# @description: Quantises the basn2c08 PNG fixture using the mid speed setting (6) and confirms output dimensions and palette cap.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --force --speed 6 --output "$tmpdir/out.png" 32 "$png"

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
w = int(tok()); h = int(tok()); _ = int(tok())
if data[idx] in b' \t\r\n':
    idx += 1
payload = data[idx:]
ch = 1 if magic == b'P5' else 3
if (w, h) != (32, 32):
    raise SystemExit(f'unexpected dimensions {w}x{h}')
colors = {tuple(payload[i:i+ch]) for i in range(0, len(payload), ch)}
if len(colors) > 32:
    raise SystemExit(f'expected <=32 colours, got {len(colors)}')
PY
