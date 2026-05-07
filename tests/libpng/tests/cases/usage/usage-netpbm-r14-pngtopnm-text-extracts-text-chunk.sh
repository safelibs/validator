#!/usr/bin/env bash
# @testcase: usage-netpbm-r14-pngtopnm-text-extracts-text-chunk
# @title: netpbm pngtopnm -text dumps tEXt keyword and value into a side file
# @description: Builds a PNG containing a tEXt "Author Alice" chunk with pnmtopng -text and decodes it back with pngtopnm -text=<file>, asserting the side-file pngtopnm writes contains both the keyword "Author" and the value "Alice" — locking in pngtopnm's tEXt-extraction path which is distinct from -alpha and -mix.
# @timeout: 180
# @tags: usage, png, netpbm, text
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.ppm" <<'PY'
import sys
W, H = 24, 24
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes((x * 10 & 0xff, y * 10 & 0xff, 64))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

printf 'Author Alice\n' >"$tmpdir/text.txt"
pnmtopng -text "$tmpdir/text.txt" "$tmpdir/in.ppm" >"$tmpdir/in.png"

# Decode back, asking pngtopnm to dump the text chunk into a side file.
pngtopnm -text="$tmpdir/extracted.txt" "$tmpdir/in.png" >"$tmpdir/back.pnm"

validator_require_file "$tmpdir/extracted.txt"
validator_assert_contains "$tmpdir/extracted.txt" 'Author'
validator_assert_contains "$tmpdir/extracted.txt" 'Alice'
# The decoded image must still be a valid PNM (P6 magic).
head -c 2 "$tmpdir/back.pnm" >"$tmpdir/magic"
[[ "$(cat "$tmpdir/magic")" == "P6" ]] || {
  printf 'expected P6 PNM magic on decoded image\n' >&2
  exit 1
}
