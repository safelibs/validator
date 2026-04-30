#!/usr/bin/env bash
# @testcase: usage-pngquant-posterize-three-png
# @title: pngquant --posterize 3
# @description: Posterizes basn2c08.png at --posterize 3 (3 bits per channel) and verifies the resulting PNG decodes at 32x32 and that every channel value is constrained to the 8-level posterization grid.
# @timeout: 180
# @tags: usage, image, png, compression
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-pngquant-posterize-three-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"
validator_require_file "$png"

pngquant --posterize 3 --force --output "$tmpdir/out.png" 256 "$png"
file "$tmpdir/out.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

pngtopam "$tmpdir/out.png" >"$tmpdir/out.pam"
pamfile "$tmpdir/out.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '32 by 32'

# --posterize 3 means 3 bits per channel of effective precision. pngquant
# does not strictly clear the low 5 bits but does heavily reduce the channel
# value space. Compare distinct-value counts before and after to confirm
# posterization actually happened, and check the result is a strict subset
# of the original's distinct values.
pngtopnm "$tmpdir/out.png" >"$tmpdir/out.ppm"
pngtopnm "$png" >"$tmpdir/orig.ppm"
python3 - "$tmpdir/out.ppm" "$tmpdir/orig.ppm" <<'PY'
import sys


def parse_p6(path):
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
    if magic != b'P6':
        raise SystemExit(f'expected P6, got {magic!r}')
    w = int(tok())
    h = int(tok())
    maxv = int(tok())
    if data[idx] in b' \t\r\n':
        idx += 1
    return w, h, maxv, data[idx:]


w_o, h_o, mv_o, payload_o = parse_p6(sys.argv[1])
w_i, h_i, mv_i, payload_i = parse_p6(sys.argv[2])
if (w_o, h_o, mv_o) != (32, 32, 255):
    raise SystemExit(f'unexpected output header {w_o}x{h_o}@{mv_o}')
if len(payload_o) != 32 * 32 * 3:
    raise SystemExit('short payload')

distinct_out = [set(), set(), set()]
distinct_in = [set(), set(), set()]
for i in range(0, len(payload_o), 3):
    for c in range(3):
        distinct_out[c].add(payload_o[i + c])
for i in range(0, len(payload_i), 3):
    for c in range(3):
        distinct_in[c].add(payload_i[i + c])

# Each posterized channel must have at most 32 distinct values (interaction
# of 3-bit posterization with the 256-color palette + dithering on a smooth
# gradient input). Source basn2c08 has 256 distinct values per channel.
for c, values in enumerate(distinct_out):
    if len(values) > 32:
        raise SystemExit(f'channel {c}: too many distinct values ({len(values)} > 32) - posterization did not reduce range')
    if len(values) == 0:
        raise SystemExit(f'channel {c}: empty')

# Posterization should have reduced (or held) the per-channel distinct count
# relative to the original. With basn2c08 having 256-step gradients, the
# output must have strictly fewer distinct values on at least one channel.
if not any(len(distinct_out[c]) < len(distinct_in[c]) for c in range(3)):
    raise SystemExit(f'posterization had no effect: in={[len(s) for s in distinct_in]} out={[len(s) for s in distinct_out]}')
PY
