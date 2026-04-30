#!/usr/bin/env bash
# @testcase: usage-netpbm-pamcut-specific-dims-png
# @title: netpbm pamcut crops PNG-derived PAM to exact dims
# @description: Decodes basn2c08.png to PAM, crops a 12x9 region anchored at offset (5,7) with pamcut, and verifies the result has exactly those dimensions and that a sample pixel matches the original at the corresponding source coordinate.
# @timeout: 180
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamcut-specific-dims-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngtopam "$png" >"$tmpdir/full.pam"
pamfile "$tmpdir/full.pam" | tee "$tmpdir/full.txt"
validator_assert_contains "$tmpdir/full.txt" '32 by 32'

pamcut -left 5 -top 7 -width 12 -height 9 "$tmpdir/full.pam" \
  >"$tmpdir/cut.pam"
pamfile "$tmpdir/cut.pam" | tee "$tmpdir/cut.txt"
validator_assert_contains "$tmpdir/cut.txt" '12 by 9'

# Pixel (0,0) of the cut must equal pixel (5,7) of the source PAM.
python3 - "$tmpdir/full.pam" "$tmpdir/cut.pam" <<'PY'
import sys

def read_pam(path):
    data = open(path, 'rb').read()
    # netpbm's pngtopam emits P6 (raw PPM, 3-byte RGB pixels) when the source
    # PNG has no alpha channel, and P7 (PAM with explicit DEPTH/TUPLTYPE) when
    # extra channels would otherwise be lost. Both share the same row-major
    # interleaved-pixel payload, so we just have to peel the right header off.
    if data.startswith(b'P7\n'):
        end = data.index(b'\nENDHDR\n') + len(b'\nENDHDR\n')
        header = data[:end].decode('ascii', errors='replace')
        payload = data[end:]
        fields = {}
        for line in header.splitlines():
            if line.startswith(('P7', 'ENDHDR', '#')) or not line.strip():
                continue
            k, _, v = line.partition(' ')
            fields[k] = v.strip()
        w = int(fields['WIDTH']); h = int(fields['HEIGHT'])
        depth = int(fields['DEPTH'])
        return w, h, depth, payload
    if data.startswith(b'P6\n'):
        # PPM: P6\n<w> <h>\n<maxval>\n<binary RGB...>
        # Skip exactly three whitespace-terminated header tokens after the magic.
        idx = 3  # past "P6\n"
        tokens = []
        while len(tokens) < 3:
            # skip comments
            while idx < len(data) and data[idx:idx+1] == b'#':
                idx = data.index(b'\n', idx) + 1
            j = idx
            while j < len(data) and data[j:j+1] not in (b' ', b'\t', b'\n', b'\r'):
                j += 1
            tokens.append(data[idx:j])
            idx = j + 1  # skip the single whitespace byte
        w = int(tokens[0]); h = int(tokens[1])
        return w, h, 3, data[idx:]
    raise SystemExit(f'expected P6 PPM or P7 PAM, got {data[:8]!r}')

fw, fh, fd, fp = read_pam(sys.argv[1])
cw, ch, cd, cp = read_pam(sys.argv[2])
if (cw, ch) != (12, 9):
    raise SystemExit(f'unexpected cut dims {cw}x{ch}')
if fd != cd:
    raise SystemExit(f'depth mismatch {fd} vs {cd}')

def pix(buf, w, depth, x, y):
    o = (y * w + x) * depth
    return tuple(buf[o:o+depth])

src = pix(fp, fw, fd, 5, 7)
dst = pix(cp, cw, cd, 0, 0)
if src != dst:
    raise SystemExit(f'cut origin {dst} != source(5,7) {src}')
print(f'cut origin pixel matches: {dst}')
PY
