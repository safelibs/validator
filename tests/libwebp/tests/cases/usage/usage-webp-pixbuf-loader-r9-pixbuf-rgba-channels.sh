#!/usr/bin/env bash
# @testcase: usage-webp-pixbuf-loader-r9-pixbuf-rgba-channels
# @title: GdkPixbuf WebP loader yields RGBA when source has alpha
# @description: Encodes an RGBA WebP via Pillow, loads it through GdkPixbuf, and verifies the pixbuf has 4 channels with has_alpha True.
# @timeout: 180
# @tags: usage, webp-pixbuf-loader, webp
# @client: webp-pixbuf-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/in.webp"
import sys
from PIL import Image
src = Image.new('RGBA', (16, 12), (10, 200, 60, 128))
src.save(sys.argv[1], 'WEBP', lossless=True)
PY

python3 - "$tmpdir/in.webp" <<'PY'
import sys
import gi
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import GdkPixbuf
pb = GdkPixbuf.Pixbuf.new_from_file(sys.argv[1])
assert pb.get_width() == 16, pb.get_width()
assert pb.get_height() == 12, pb.get_height()
assert pb.get_n_channels() == 4, pb.get_n_channels()
assert pb.get_has_alpha() is True
PY
