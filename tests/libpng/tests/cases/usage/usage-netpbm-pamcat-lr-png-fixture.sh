#!/usr/bin/env bash
# @testcase: usage-netpbm-pamcat-lr-png-fixture
# @title: netpbm pamcat -lr on PNG-derived inputs
# @description: Decodes the basn2c08 fixture twice into PAM, concatenates them left-to-right with pamcat -lr, re-encodes to PNG, and asserts the result is a 64x32 PNG.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamcat-lr-png-fixture"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopam "$png" >"$tmpdir/a.pam"
cp -a "$tmpdir/a.pam" "$tmpdir/b.pam"

pamcat -lr "$tmpdir/a.pam" "$tmpdir/b.pam" >"$tmpdir/joined.pam"

pamfile "$tmpdir/joined.pam" | tee "$tmpdir/pamfile.txt"
validator_assert_contains "$tmpdir/pamfile.txt" '64 by 32'

pnmtopng "$tmpdir/joined.pam" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# Round-trip back through pngtopam to verify libpng can decode the result and
# that the dimensions survive the PNG encode.
pngtopam "$tmpdir/out.png" >"$tmpdir/round.pam"
pamfile "$tmpdir/round.pam" | tee "$tmpdir/round.txt"
validator_assert_contains "$tmpdir/round.txt" '64 by 32'

# Spot check: the left half (cols 0..31) of joined image must equal the right
# half (cols 32..63) since both inputs are the same fixture.
python3 - "$tmpdir/joined.pam" <<'PY'
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
w = int(tok()); h = int(tok()); m = int(tok())
if data[idx] in b' \t\r\n':
    idx += 1
payload = data[idx:]
if (w, h) != (64, 32):
    raise SystemExit(f'unexpected geometry {w}x{h}')
row_bytes = w * 3
for y in range(h):
    row = payload[y*row_bytes:(y+1)*row_bytes]
    left = row[:32*3]
    right = row[32*3:]
    if left != right:
        raise SystemExit(f'mirror mismatch at row {y}')
PY
