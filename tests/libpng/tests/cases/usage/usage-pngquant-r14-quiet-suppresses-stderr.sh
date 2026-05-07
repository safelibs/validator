#!/usr/bin/env bash
# @testcase: usage-pngquant-r14-quiet-suppresses-stderr
# @title: pngquant --quiet suppresses progress messages on stderr while still writing a valid PNG
# @description: Quantises a synthetic 24x24 PNG with pngquant --quiet (the documented opposite of --verbose) and verifies that no progress lines are written to stderr while the requested output PNG is still produced — locking in the quiet-mode contract that callers rely on for scripted pipelines.
# @timeout: 120
# @tags: usage, image, png, cli, quiet
# @client: pngquant

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
        b += bytes(((x * 10) & 0xff, (y * 10) & 0xff, 64))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY
pnmtopng "$tmpdir/in.ppm" >"$tmpdir/in.png"

# --quiet must produce no stderr output for a successful conversion.
pngquant --force --quiet -o "$tmpdir/out.png" 16 "$tmpdir/in.png" 2>"$tmpdir/stderr"

stderr_size=$(wc -c <"$tmpdir/stderr")
[[ "$stderr_size" == "0" ]] || {
  printf 'pngquant --quiet wrote %s bytes to stderr; expected zero\n' "$stderr_size" >&2
  cat "$tmpdir/stderr" >&2
  exit 1
}

python3 - "$tmpdir/out.png" <<'PY'
import struct, sys
data = open(sys.argv[1], 'rb').read()
assert data[:8] == b'\x89PNG\r\n\x1a\n'
w, h, depth, ctype = struct.unpack('>IIBB', data[16:26])
assert (w, h) == (24, 24), (w, h)
assert ctype == 3, f'expected paletted PNG (ctype 3), got {ctype}'
PY
