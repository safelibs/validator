#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r9-pixbuf-rgb-channels
# @title: gdk-pixbuf-pixdata decodes a non-alpha WebP via the loader
# @description: Encodes a lossy non-alpha WebP via cwebp then runs gdk-pixbuf-pixdata to confirm the GdkPixbuf WebP loader decodes it and emits a non-empty pixdata blob with the GdkP magic.
# @timeout: 180
# @tags: usage, webp-pixbuf-loader, webp
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.ppm"
import sys
W, H = 24, 18
b = bytearray()
for y in range(H):
    for x in range(W):
        b += bytes(((x * 9) & 0xff, (y * 11) & 0xff, ((x + y) * 5) & 0xff))
open(sys.argv[1], 'wb').write(f'P6\n{W} {H}\n255\n'.encode() + b)
PY

cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"

gdk-pixbuf-query-loaders >"$tmpdir/loaders.txt"
grep -Eqi '(WebP|webp)' "$tmpdir/loaders.txt"

gdk-pixbuf-pixdata "$tmpdir/in.webp" "$tmpdir/out.gdkp"
[[ -s "$tmpdir/out.gdkp" ]]
head -c 4 "$tmpdir/out.gdkp" | od -An -tx1 | tr -d ' \n' | grep -q '^47646b50'
