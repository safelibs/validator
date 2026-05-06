#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r9-pixbuf-rgb-channels
# @title: GdkPixbuf WebP loader exposes 3-channel pixbuf
# @description: Loads a non-alpha lossy WebP via gi.repository.GdkPixbuf.Pixbuf.new_from_file and verifies the pixbuf reports 3 channels with width/height matching the source.
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

python3 - "$tmpdir/in.webp" <<'PY'
import sys
import gi
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import GdkPixbuf
pb = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1])
assert pb.get_width() == 24, pb.get_width()
assert pb.get_height() == 18, pb.get_height()
assert pb.get_n_channels() == 3, pb.get_n_channels()
assert pb.get_has_alpha() is False
PY
