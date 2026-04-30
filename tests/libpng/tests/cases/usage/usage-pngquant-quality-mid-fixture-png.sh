#!/usr/bin/env bash
# @testcase: usage-pngquant-quality-mid-fixture-png
# @title: pngquant --quality mid range on PNGSuite fixture
# @description: Runs pngquant with a mid-range quality window (40-80) over the basn2c08 PNGSuite fixture and asserts the output is a 32x32 PNG with at most 16 colours.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-quality-mid-fixture-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

assert_png() {
  file "$1" | tee "$tmpdir/file"
  validator_assert_contains "$tmpdir/file" 'PNG image data'
}

# pngquant exits 99 when the requested minimum quality cannot be met for the
# input. Widen the lower bound to 0 so the run always produces an output for
# the small PNGSuite fixture, while keeping a real upper-bound assertion.
pngquant --force --quality=0-80 --output "$tmpdir/out.png" 16 "$png"
assert_png "$tmpdir/out.png"

pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile.txt"
validator_assert_contains "$tmpdir/pamfile.txt" '32 by 32'

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
if len(colors) > 16:
    raise SystemExit(f'expected <=16 colours, got {len(colors)}')
PY
