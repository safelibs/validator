#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
open(sys.argv[1],'wb').write(b'P6\n3 2\n255\n'+bytes(range(18)))
PY
cjpeg "$tmpdir/in.ppm" >"$tmpdir/a.jpg"; jpegtran -rotate 90 "$tmpdir/a.jpg" >"$tmpdir/r.jpg"; djpeg -ppm "$tmpdir/r.jpg" >"$tmpdir/r.ppm"; head -n 3 "$tmpdir/r.ppm"
