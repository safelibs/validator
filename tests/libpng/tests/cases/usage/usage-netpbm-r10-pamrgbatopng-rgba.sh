#!/usr/bin/env bash
# @testcase: usage-netpbm-r10-pamrgbatopng-rgba
# @title: netpbm pamrgbatopng emits an RGBA PNG from a synthetic PAM
# @description: Builds a 2x1 PAM with the RGB_ALPHA tuple type and converts it with pamrgbatopng, asserting the resulting PNG announces 8-bit RGBA via the file(1) classifier.
# @timeout: 60
# @tags: usage, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pam" <<'PY'
import sys
header = (
    b'P7\n'
    b'WIDTH 2\n'
    b'HEIGHT 1\n'
    b'DEPTH 4\n'
    b'MAXVAL 255\n'
    b'TUPLTYPE RGB_ALPHA\n'
    b'ENDHDR\n'
)
body = bytes([255, 0, 0, 128, 0, 255, 0, 255])
open(sys.argv[1], 'wb').write(header + body)
PY

pamrgbatopng "$tmpdir/in.pam" >"$tmpdir/out.png"
file "$tmpdir/out.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
validator_assert_contains "$tmpdir/file.txt" 'RGBA'
validator_assert_contains "$tmpdir/file.txt" '2 x 1'
