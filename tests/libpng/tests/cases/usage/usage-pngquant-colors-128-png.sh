#!/usr/bin/env bash
# @testcase: usage-pngquant-colors-128-png
# @title: pngquant --colors 128 quantises PNG fixture
# @description: Quantises basn2c08.png with pngquant --colors 128 and verifies the output is a valid PNG whose decoded palette has at most 128 unique colours.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-colors-128-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --force --output "$tmpdir/out.png" 128 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# Round-trip: decoded image must keep the original 32x32 dimensions and have
# at most 128 distinct colours after a --colors 128 quantisation.
pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'

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
channels = 1 if magic == b'P5' else 3
colors = {tuple(payload[i:i+channels]) for i in range(0, len(payload), channels)}
if len(colors) > 128:
    raise SystemExit(f'expected <=128 colours after --colors 128, got {len(colors)}')
print(f'colors after quantisation: {len(colors)}')
PY
