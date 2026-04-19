#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
open(sys.argv[1],'wb').write(b'P6\n2 2\n255\n'+bytes([255,0,0,0,255,0,0,0,255,255,255,255]))
PY
cjpeg "$tmpdir/in.ppm" >"$tmpdir/a.jpg"; djpeg -ppm "$tmpdir/a.jpg" >"$tmpdir/out.ppm"; head -n 3 "$tmpdir/out.ppm"; file "$tmpdir/a.jpg"
