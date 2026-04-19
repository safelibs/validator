#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    python3 - <<'PY' "$tmpdir/in.ppm"
import sys
open(sys.argv[1], 'wb').write(b'P6\n4 3\n255\n' + bytes([255,0,0,0,255,0,0,0,255,255,255,0,255,0,255,0,255,255,40,40,40,220,220,220,100,20,30,20,100,30,20,30,100,200,120,20]))
PY
    cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
    gdk-pixbuf-thumbnailer -s 32 "$tmpdir/in.webp" "$tmpdir/thumb.png"
file "$tmpdir/thumb.png"