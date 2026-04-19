#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
open(sys.argv[1],'wb').write(b'P6\n2 2\n255\n'+bytes([10,20,30,40,50,60,70,80,90,100,110,120]))
PY
cjpeg -progressive "$tmpdir/in.ppm" >"$tmpdir/p.jpg"; djpeg -grayscale "$tmpdir/p.jpg" >"$tmpdir/g.pgm"; head -n 3 "$tmpdir/g.pgm"; file "$tmpdir/p.jpg"
