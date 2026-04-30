#!/usr/bin/env bash
# @testcase: usage-netpbm-pamstack-combine-bands-png
# @title: netpbm pamstack combines RGB + alpha bands into RGBA PNG
# @description: Builds three single-band PGM planes derived from a PNG round-trip plus a synthesised alpha band, stacks them with pamstack into an RGB_ALPHA PAM, encodes the result with pamtopng, and verifies pngtopam -alpha extracts the original alpha mask byte-for-byte.
# @timeout: 180
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pamstack-combine-bands-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build deterministic single-band 4x2 grayscale planes for R, G, B.
printf 'P2\n4 2\n255\n200 150 100 50\n40 80 120 160\n' >"$tmpdir/r.pgm"
printf 'P2\n4 2\n255\n10 20 30 40\n90 80 70 60\n' >"$tmpdir/g.pgm"
printf 'P2\n4 2\n255\n5 25 45 65\n75 95 115 135\n' >"$tmpdir/b.pgm"
printf 'P2\n4 2\n255\n255 192 128 64\n0 64 128 255\n' >"$tmpdir/a.pgm"

pamstack -tupletype=RGB_ALPHA "$tmpdir/r.pgm" "$tmpdir/g.pgm" "$tmpdir/b.pgm" "$tmpdir/a.pgm" \
  >"$tmpdir/rgba.pam" 2>"$tmpdir/pamstack.err"
pamfile "$tmpdir/rgba.pam" | tee "$tmpdir/pamfile"
validator_assert_contains "$tmpdir/pamfile" '4 by 2'
validator_assert_contains "$tmpdir/pamfile" 'RGB_ALPHA'

# Encode the stacked RGBA PAM as a PNG.
pamtopng "$tmpdir/rgba.pam" >"$tmpdir/rgba.png"
file "$tmpdir/rgba.png" | tee "$tmpdir/file"
validator_assert_contains "$tmpdir/file" 'PNG image data'

# Round-trip: pull the alpha plane out with pngtopam -alpha and confirm it
# matches the alpha plane we fed in.
pngtopam -alpha "$tmpdir/rgba.png" >"$tmpdir/alpha-out.pgm"
pamfile "$tmpdir/alpha-out.pgm" | tee "$tmpdir/alpha-pamfile"
validator_assert_contains "$tmpdir/alpha-pamfile" '4 by 2'

python3 - "$tmpdir/a.pgm" "$tmpdir/alpha-out.pgm" <<'PY'
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
    w = int(tok())
    h = int(tok())
    maxv = int(tok())
    if data[idx] in b' \t\r\n':
        idx += 1
    payload = list(data[idx:])
    if magic == b'P5':
        return w, h, maxv, payload
    if magic == b'P2':
        # Re-tokenize ASCII pixel values.
        idx_local = idx
        values = []
        while idx_local < len(data):
            while idx_local < len(data) and data[idx_local] in b' \t\r\n':
                idx_local += 1
            if idx_local >= len(data):
                break
            s = idx_local
            while idx_local < len(data) and data[idx_local] not in b' \t\r\n':
                idx_local += 1
            tok_bytes = data[s:idx_local]
            if not tok_bytes:
                continue
            values.append(int(tok_bytes))
        return w, h, maxv, values
    raise SystemExit(f'unsupported magic {magic!r}')


a_w, a_h, a_max, a_payload = read_image(sys.argv[1])
o_w, o_h, o_max, o_payload = read_image(sys.argv[2])
if (a_w, a_h) != (o_w, o_h):
    raise SystemExit(f'dim mismatch: {(a_w, a_h)} vs {(o_w, o_h)}')
if a_max != o_max:
    raise SystemExit(f'maxval mismatch: {a_max} vs {o_max}')
if a_payload != o_payload:
    raise SystemExit(f'alpha payload mismatch: {a_payload} vs {o_payload}')
PY
