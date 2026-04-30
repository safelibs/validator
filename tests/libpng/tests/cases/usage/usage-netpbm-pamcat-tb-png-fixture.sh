#!/usr/bin/env bash
# @testcase: usage-netpbm-pamcat-tb-png-fixture
# @title: netpbm pamcat -tb on PNG-derived inputs
# @description: Decodes the basn2c08 fixture twice into PAM, concatenates them top-to-bottom with pamcat -tb, re-encodes to PNG, and asserts the result is a 32x64 PNG that round-trips through libpng.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamcat-tb-png-fixture"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopam "$png" >"$tmpdir/a.pam"
cp -a "$tmpdir/a.pam" "$tmpdir/b.pam"

pamcat -tb "$tmpdir/a.pam" "$tmpdir/b.pam" >"$tmpdir/stacked.pam"

pamfile "$tmpdir/stacked.pam" | tee "$tmpdir/pamfile.txt"
validator_assert_contains "$tmpdir/pamfile.txt" '32 by 64'

pnmtopng "$tmpdir/stacked.pam" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopam "$tmpdir/out.png" >"$tmpdir/round.pam"
pamfile "$tmpdir/round.pam" | tee "$tmpdir/round.txt"
validator_assert_contains "$tmpdir/round.txt" '32 by 64'

# Spot check: the top 32 rows must equal the bottom 32 rows of the joined
# image, since both inputs are the same fixture.
python3 - "$tmpdir/stacked.pam" <<'PY'
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
if (w, h) != (32, 64):
    raise SystemExit(f'unexpected geometry {w}x{h}')
row_bytes = w * 3
top = payload[:32*row_bytes]
bottom = payload[32*row_bytes:64*row_bytes]
if top != bottom:
    raise SystemExit('expected top half == bottom half for duplicate inputs')
PY
