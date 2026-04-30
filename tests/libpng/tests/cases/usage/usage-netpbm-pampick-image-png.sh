#!/usr/bin/env bash
# @testcase: usage-netpbm-pampick-image-png
# @title: netpbm pampick selects image from multi-image stream
# @description: Concatenates two PNG-derived PAM images into a multi-image stream and uses pampick to extract the second image, verifying its content.
# @timeout: 180
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# First image: PNG fixture (32x32).
png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"
pngtopam "$png" >"$tmpdir/a.pam"

# Second image: synthesised 2x2 PNG-derived PAM with deterministic pixels.
printf 'P3\n2 2\n255\n10 20 30  40 50 60\n70 80 90  100 110 120\n' >"$tmpdir/b.ppm"
pnmtopng "$tmpdir/b.ppm" >"$tmpdir/b.png"
pngtopam "$tmpdir/b.png" >"$tmpdir/b.pam"

# Build the multi-image stream and pick image #1 (the second image).
cat "$tmpdir/a.pam" "$tmpdir/b.pam" >"$tmpdir/multi.pam"
pampick 1 <"$tmpdir/multi.pam" >"$tmpdir/picked.pam" 2>"$tmpdir/pampick.err"
validator_assert_contains "$tmpdir/pampick.err" 'Image #1'

pamfile "$tmpdir/picked.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '2 by 2'

# Convert back to ppm and check the deterministic pixel values are intact.
pamtopnm "$tmpdir/picked.pam" >"$tmpdir/picked.ppm"
python3 - "$tmpdir/picked.ppm" <<'PY'
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
w = int(tok()); h = int(tok()); _ = int(tok())
if data[idx] in b' \t\r\n':
    idx += 1
payload = list(data[idx:])
if (w, h) != (2, 2):
    raise SystemExit(f'unexpected dimensions {w}x{h}')
expected = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120]
if payload != expected:
    raise SystemExit(f'unexpected payload {payload}')
PY
