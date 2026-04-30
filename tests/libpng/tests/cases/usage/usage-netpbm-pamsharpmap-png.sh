#!/usr/bin/env bash
# @testcase: usage-netpbm-pamsharpmap-png
# @title: netpbm pamsharpmap on PNG fixture
# @description: Decodes basn2c08.png to PAM, runs pamsharpmap to apply local-contrast sharpening, and verifies the output preserves dimensions and channel depth and survives a pnmtopng round-trip.
# @timeout: 180
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamsharpmap-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopam "$png" >"$tmpdir/in.pam"
pamfile "$tmpdir/in.pam" | tee "$tmpdir/in.txt"
validator_assert_contains "$tmpdir/in.txt" '32 by 32'

# pamsharpmap takes its input on stdin.
pamsharpmap <"$tmpdir/in.pam" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" '32 by 32'

# Round-trip back to PNG to confirm the sharpened PAM is still valid for libpng.
pnmtopng "$tmpdir/out.pam" >"$tmpdir/out.png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# Header-level check: input and output PAMs must agree on WIDTH/HEIGHT/DEPTH.
python3 - "$tmpdir/in.pam" "$tmpdir/out.pam" <<'PY'
import sys

def read_header(path):
    data = open(path, 'rb').read()
    # pngtopam emits P6 (raw PPM) for RGB PNGs without alpha and P7 (PAM)
    # for any image needing an explicit DEPTH/TUPLTYPE; pamsharpmap preserves
    # whichever format it received. Accept either header format.
    if data.startswith(b'P7\n'):
        end = data.index(b'\nENDHDR\n')
        header = data[:end].decode('ascii', errors='replace')
        fields = {}
        for line in header.splitlines():
            if line.startswith(('P7', '#')) or not line.strip():
                continue
            k, _, v = line.partition(' ')
            fields[k] = v.strip()
        return int(fields['WIDTH']), int(fields['HEIGHT']), int(fields['DEPTH'])
    if data.startswith(b'P6\n'):
        idx = 3
        tokens = []
        while len(tokens) < 3:
            while idx < len(data) and data[idx:idx+1] == b'#':
                idx = data.index(b'\n', idx) + 1
            j = idx
            while j < len(data) and data[j:j+1] not in (b' ', b'\t', b'\n', b'\r'):
                j += 1
            tokens.append(data[idx:j])
            idx = j + 1
        return int(tokens[0]), int(tokens[1]), 3
    raise SystemExit(f'expected P6 PPM or P7 PAM, got {data[:8]!r}')

a = read_header(sys.argv[1])
b = read_header(sys.argv[2])
if a != b:
    raise SystemExit(f'shape mismatch in={a} out={b}')
print(f'pamsharpmap preserved shape: {a}')
PY
