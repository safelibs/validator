#!/usr/bin/env bash
# @testcase: usage-pngquant-colors-256-png
# @title: pngquant --colors 256 (max palette)
# @description: Quantises a PNG fixture with the maximum palette size of 256 and confirms PNG output is still produced.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-colors-256-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

pngquant --force --output "$tmpdir/out.png" 256 "$png"
assert_png "$tmpdir/out.png"

# Round-trip back through pngtopam and confirm dimensions are preserved.
pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile.txt"
validator_assert_contains "$tmpdir/pamfile.txt" '32 by 32'

# At -colors 256 every distinct colour from a 32x32 fixture should fit, so the
# output palette size is bounded by 256.
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
    raise SystemExit(f'expected <=256 colours after --colors 256, got {len(colors)}')
PY
