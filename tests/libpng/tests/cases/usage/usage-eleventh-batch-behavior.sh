#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/pnm_assert.py" <<'PYCASE'
import ast
import sys

def read_image(path):
    data = open(path, 'rb').read()
    idx = 0
    def skip_ws():
        nonlocal idx
        while idx < len(data):
            if data[idx] in b' \t\r\n':
                idx += 1
            elif data[idx] == 35:
                while idx < len(data) and data[idx] not in (10, 13):
                    idx += 1
            else:
                break
    def token():
        nonlocal idx
        skip_ws()
        start = idx
        while idx < len(data) and data[idx] not in b' \t\r\n':
            idx += 1
        return data[start:idx]
    magic = token()
    width = int(token())
    height = int(token())
    maxval = int(token())
    if idx < len(data) and data[idx] in b' \t\r\n':
        idx += 1
    channels = 1 if magic == b'P5' else 3
    return width, height, channels, maxval, list(data[idx:])

cmd = sys.argv[1]
if cmd == 'values':
    width, height, channels, maxval, payload = read_image(sys.argv[2])
    expected = ast.literal_eval(sys.argv[6])
    assert (width, height, channels) == (int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]))
    assert payload == expected, payload
elif cmd == 'shape':
    width, height, channels, maxval, payload = read_image(sys.argv[2])
    assert (width, height, channels) == (int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]))
elif cmd == 'maxval':
    width, height, channels, maxval, payload = read_image(sys.argv[2])
    assert maxval == int(sys.argv[3]), maxval
else:
    raise SystemExit(cmd)
PYCASE

assert_values() { python3 "$tmpdir/pnm_assert.py" values "$1" "$2" "$3" "$4" "$5"; }
assert_shape() { python3 "$tmpdir/pnm_assert.py" shape "$1" "$2" "$3" "$4"; }

case "$case_id" in
  usage-netpbm-batch11-pngtopam-pamfile)
    printf 'P2\n2 2\n255\n0 255\n128 64\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopam "$tmpdir/input.png" >"$tmpdir/out.pam"
    pamfile "$tmpdir/out.pam" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'PGM raw, 2 by 2'
    ;;
  usage-netpbm-batch11-pamdice-tiles)
    printf 'P2\n2 2\n255\n0 50\n100 150\n' >"$tmpdir/input.pgm"
    mkdir "$tmpdir/tiles"
    pamdice -width=1 -height=1 -outstem="$tmpdir/tiles/tile" "$tmpdir/input.pgm"
    test -f "$tmpdir/tiles/tile_0_0.pgm"
    test -f "$tmpdir/tiles/tile_0_1.pgm"
    test -f "$tmpdir/tiles/tile_1_0.pgm"
    test -f "$tmpdir/tiles/tile_1_1.pgm"
    ;;
  usage-netpbm-batch11-pamdeinterlace-height)
    printf 'P2\n2 2\n255\n10 20\n30 40\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pamdeinterlace >"$tmpdir/out.pgm"
    assert_shape "$tmpdir/out.pgm" 2 1 1
    ;;
  usage-netpbm-batch11-pnmarith-add)
    printf 'P2\n2 1\n255\n0 100\n' >"$tmpdir/a.pgm"
    printf 'P2\n2 1\n255\n10 20\n' >"$tmpdir/b.pgm"
    pnmarith -add "$tmpdir/a.pgm" "$tmpdir/b.pgm" >"$tmpdir/out.pgm"
    assert_values "$tmpdir/out.pgm" 2 1 1 '[10, 120]'
    ;;
  usage-netpbm-batch11-pnmgamma-shape)
    printf 'P2\n2 1\n255\n64 128\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmgamma 2.0 >"$tmpdir/out.pgm"
    assert_shape "$tmpdir/out.pgm" 2 1 1
    ;;
  usage-netpbm-batch11-pamthreshold-bw)
    printf 'P2\n2 1\n255\n0 255\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pamthreshold >"$tmpdir/out.pam"
    pamfile "$tmpdir/out.pam" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'BLACKANDWHITE'
    ;;
  usage-netpbm-batch11-pnmnorm-shape)
    printf 'P2\n2 2\n255\n0 255\n128 64\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmnorm -bpercent 0 -wpercent 0 >"$tmpdir/out.pgm"
    assert_shape "$tmpdir/out.pgm" 2 2 1
    ;;
  usage-netpbm-batch11-pnmrotate-right-angle)
    printf 'P2\n2 1\n255\n0 255\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmrotate 90 >"$tmpdir/out.pgm"
    assert_shape "$tmpdir/out.pgm" 5 2 1
    ;;
  usage-netpbm-batch11-pnmshear-width)
    printf 'P2\n2 1\n255\n0 255\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pnmshear 10 >"$tmpdir/out.pgm"
    assert_shape "$tmpdir/out.pgm" 3 1 1
    ;;
  usage-netpbm-batch11-pamstretch-double)
    printf 'P2\n2 2\n255\n0 50\n100 150\n' >"$tmpdir/input.pgm"
    pnmtopng "$tmpdir/input.pgm" >"$tmpdir/input.png"
    pngtopnm "$tmpdir/input.png" | pamstretch 2 >"$tmpdir/out.pgm"
    assert_shape "$tmpdir/out.pgm" 4 4 1
    ;;
  *)
    printf 'unknown libpng eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
