#!/usr/bin/env bash
# @testcase: usage-pngquant-tiny-1x1-png
# @title: pngquant on a 1x1 PNG edge case
# @description: Generates a minimal 1x1 RGB PNG via netpbm and confirms pngquant produces a 1x1 single-colour PNG output.
# @timeout: 120
# @tags: usage, image, png, edge-case
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a 1x1 RGB PNG (deterministic single pixel value).
printf 'P3\n1 1\n255\n200 100 50\n' >"$tmpdir/in.ppm"
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"
file "$tmpdir/in.png" | tee "$tmpdir/file-in"
validator_assert_contains "$tmpdir/file-in" 'PNG image data'

pngquant --force --output "$tmpdir/out.png" 256 "$tmpdir/in.png"

file "$tmpdir/out.png" | tee "$tmpdir/file-out"
validator_assert_contains "$tmpdir/file-out" 'PNG image data'

pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '1 by 1'

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
if (w, h) != (1, 1):
    raise SystemExit(f'expected 1x1 output, got {w}x{h}')
colors = {tuple(payload[i:i+ch]) for i in range(0, len(payload), ch)}
if len(colors) != 1:
    raise SystemExit(f'expected exactly one colour for 1x1, got {len(colors)}')
PY
