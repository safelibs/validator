#!/usr/bin/env bash
# @testcase: usage-netpbm-pamcomp-align-center-png
# @title: netpbm pamcomp -align center on PNG fixture
# @description: Crops a 16x16 patch out of basn2c08.png and composites it back onto the original via pamcomp -align center -valign middle, then re-encodes the result to PNG and verifies the geometry matches the underlying image.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamcomp-align-center-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopam "$png" >"$tmpdir/under.pam"
pamcut -left 8 -top 8 -width 16 -height 16 "$tmpdir/under.pam" >"$tmpdir/over.pam"

pamfile "$tmpdir/over.pam" | tee "$tmpdir/over.txt"
validator_assert_contains "$tmpdir/over.txt" '16 by 16'

pamcomp -align=center -valign=middle "$tmpdir/over.pam" "$tmpdir/under.pam" \
  >"$tmpdir/comp.pam"

pamfile "$tmpdir/comp.pam" | tee "$tmpdir/comp.txt"
# pamcomp output dimensions match the underlying image (32x32).
validator_assert_contains "$tmpdir/comp.txt" '32 by 32'

pnmtopng "$tmpdir/comp.pam" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# The composite at center+middle places the 16x16 overlay at offset (8,8).
# Inside that region the result must equal the corresponding portion of the
# original; outside it must equal the underlying pixels. Verify a few pixels.
python3 - "$tmpdir/under.pam" "$tmpdir/comp.pam" <<'PY'
import sys

def read_image(path):
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
    magic = tok()
    w = int(tok()); h = int(tok()); m = int(tok())
    if data[idx] in b' \t\r\n':
        idx += 1
    return w, h, list(data[idx:])

uw, uh, upx = read_image(sys.argv[1])
cw, ch, cpx = read_image(sys.argv[2])
if (uw, uh) != (cw, ch):
    raise SystemExit('dimension mismatch')

def pix(buf, w, x, y):
    o = (y * w + x) * 3
    return buf[o], buf[o+1], buf[o+2]

# Outside the centred 16x16 patch (e.g. (0,0) and (31,31)) the composite must
# equal the underlying image.
for x, y in [(0, 0), (31, 31), (0, 31), (31, 0)]:
    if pix(upx, uw, x, y) != pix(cpx, cw, x, y):
        raise SystemExit(f'expected underlying pixel preserved at ({x},{y})')

# Inside the patch, with full opacity, the composite equals the underlying too
# (since the overlay was cut from the same image).
for x, y in [(15, 15), (16, 16)]:
    if pix(upx, uw, x, y) != pix(cpx, cw, x, y):
        raise SystemExit(f'expected matching pixel at ({x},{y})')
PY
