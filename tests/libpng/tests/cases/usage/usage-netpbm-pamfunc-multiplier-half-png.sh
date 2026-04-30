#!/usr/bin/env bash
# @testcase: usage-netpbm-pamfunc-multiplier-half-png
# @title: netpbm pamfunc -multiplier 0.5 on PNG fixture
# @description: Converts basn2c08.png to PAM, applies pamfunc -multiplier 0.5, re-encodes to PNG, and verifies every output sample is at most half (rounded) the corresponding input sample.
# @timeout: 180
# @tags: usage, image, png
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamfunc-multiplier-half-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopam "$png" >"$tmpdir/in.pam"
pamfunc -multiplier 0.5 "$tmpdir/in.pam" >"$tmpdir/half.pam"

pamfile "$tmpdir/half.pam" | tee "$tmpdir/pamfile.txt"
validator_assert_contains "$tmpdir/pamfile.txt" '32 by 32'
validator_assert_contains "$tmpdir/pamfile.txt" 'PPM raw'

pnmtopng "$tmpdir/half.pam" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

python3 - "$tmpdir/in.pam" "$tmpdir/half.pam" <<'PY'
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
    if magic not in (b'P5', b'P6'):
        raise SystemExit(f'unsupported magic {magic!r}')
    w = int(tok()); h = int(tok()); m = int(tok())
    if data[idx] in b' \t\r\n':
        idx += 1
    return w, h, m, list(data[idx:])

iw, ih, im, ipx = read_image(sys.argv[1])
hw, hh, hm, hpx = read_image(sys.argv[2])
if (iw, ih) != (hw, hh):
    raise SystemExit(f'shape mismatch {iw}x{ih} vs {hw}x{hh}')
if len(ipx) != len(hpx):
    raise SystemExit('payload length mismatch')

# pamfunc rounds; allow +/- 1 around floor(x/2).
violations = 0
for a, b in zip(ipx, hpx):
    expected = a // 2
    if not (expected - 1 <= b <= expected + 1):
        violations += 1
if violations:
    raise SystemExit(f'{violations} samples drifted from half-input')
PY
