#!/usr/bin/env bash
# @testcase: usage-netpbm-pnmcat-lr-multi-png
# @title: netpbm pnmcat -lr concatenates multiple PNG-derived PGMs
# @description: Decodes three single-pixel PGMs (re-encoded through PNG via pnmtopng/pngtopnm) and concatenates them with pnmcat -lr; verifies the result is a 3x1 grayscale image with the expected pixel triple.
# @timeout: 120
# @tags: usage, image, png, netpbm
# @client: netpbm

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-netpbm-pnmcat-lr-multi-png"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Three distinct single-pixel grayscale tiles, each round-tripped through PNG.
make_tile() {
  local value=$1
  local out=$2
  printf 'P2\n1 1\n255\n%s\n' "$value" >"$tmpdir/seed.pgm"
  pnmtopng "$tmpdir/seed.pgm" >"$tmpdir/seed.png"
  file "$tmpdir/seed.png" | tee "$tmpdir/seed.file"
  validator_assert_contains "$tmpdir/seed.file" 'PNG image data'
  pngtopnm "$tmpdir/seed.png" >"$out"
}
make_tile 10 "$tmpdir/a.pgm"
make_tile 90 "$tmpdir/b.pgm"
make_tile 240 "$tmpdir/c.pgm"

pnmcat -lr "$tmpdir/a.pgm" "$tmpdir/b.pgm" "$tmpdir/c.pgm" \
  >"$tmpdir/joined.pgm"

python3 - "$tmpdir/joined.pgm" <<'PY'
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
if magic != b'P5':
    raise SystemExit(f'expected P5, got {magic!r}')
w = int(tok()); h = int(tok()); _ = int(tok())
if data[idx] in b' \t\r\n':
    idx += 1
payload = list(data[idx:])
if (w, h) != (3, 1):
    raise SystemExit(f'expected 3x1, got {w}x{h}')
if payload != [10, 90, 240]:
    raise SystemExit(f'unexpected payload {payload}')
print(f'pnmcat -lr payload OK: {payload}')
PY

# And the joined image must round-trip cleanly back through libpng.
pnmtopng "$tmpdir/joined.pgm" >"$tmpdir/joined.png"
file "$tmpdir/joined.png" | tee "$tmpdir/joined.file"
validator_assert_contains "$tmpdir/joined.file" 'PNG image data'
