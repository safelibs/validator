#!/usr/bin/env bash
# @testcase: usage-vips-r21-hist-find-from-jpeg-256x1
# @title: vips hist_find on a JPEG yields a 256x1 histogram image with 3 bands
# @description: Encodes a 64x48 RGB JPEG, decodes it through vips hist_find, asserts the resulting .v image is exactly 256x1 with 3 bands and that the format string emitted by vipsheader -f format equals VIPS_FORMAT_UINT - locking in libjpeg-turbo's RGB decode followed by vips's per-channel histogram synthesis at its standard 256-bin layout.
# @timeout: 180
# @tags: usage, vips, hist-find, jpeg, histogram, r21
# @client: vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" <<'PY'
import sys
from pathlib import Path
from PIL import Image

base = Path(sys.argv[1])
out = base / "in.jpg"
W, H = 64, 48
im = Image.new("RGB", (W, H))
im.putdata([((x * 9) & 255, (y * 5) & 255, ((x + y) * 3) & 255)
             for y in range(H) for x in range(W)])
im.save(out, "JPEG", quality=90)
PY

vips hist_find "$tmpdir/in.jpg" "$tmpdir/h.v"
w=$(vipsheader -f width "$tmpdir/h.v")
h=$(vipsheader -f height "$tmpdir/h.v")
bands=$(vipsheader -f bands "$tmpdir/h.v")
fmt=$(vipsheader -f format "$tmpdir/h.v")

[[ "$w" == "256" ]] || { printf 'expected width 256, got %s\n' "$w" >&2; exit 1; }
[[ "$h" == "1" ]] || { printf 'expected height 1, got %s\n' "$h" >&2; exit 1; }
[[ "$bands" == "3" ]] || { printf 'expected 3 bands, got %s\n' "$bands" >&2; exit 1; }
[[ "$fmt" == *UINT* ]] || { printf 'expected UINT format, got %s\n' "$fmt" >&2; exit 1; }
