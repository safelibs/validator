#!/usr/bin/env bash
# @testcase: usage-pngquant-speed-eight-png
# @title: pngquant --speed 8 PNG
# @description: Runs pngquant with --speed 8 on basn2c08.png and verifies a valid PNG output preserving dimensions, sanity-checking the fast quantisation path.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-speed-eight-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --speed 8 --force --output "$tmpdir/out.png" 256 "$png"

file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'

# At --speed 8 with --colors 256 a 32x32 fixture must fit under 256 unique colours.
python3 - "$tmpdir/out.pam" <<'PY'
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
colors = {tuple(payload[i:i+ch]) for i in range(0, len(payload), ch)}
if len(colors) > 256:
    raise SystemExit(f'expected <=256 colours, got {len(colors)}')
PY
