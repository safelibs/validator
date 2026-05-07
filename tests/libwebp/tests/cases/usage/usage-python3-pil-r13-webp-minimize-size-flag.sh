#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-webp-minimize-size-flag
# @title: Pillow animated WEBP minimize_size=True round-trips frame count
# @description: Saves a 3-frame WEBP animation with minimize_size=True (which forces libwebpmux to recompute frame deltas) and confirms n_frames is preserved on read-back, exercising the libwebpmux size-minimisation path.
# @timeout: 180
# @tags: usage, python3-pil, webp, animation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/min.webp"
import sys
from PIL import Image

frames = [Image.new('RGB', (16, 16), (40 + 50 * i, 90, 200 - 50 * i)) for i in range(3)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=80, loop=0, minimize_size=True)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.n_frames == 3, im.n_frames
    assert im.size == (16, 16), im.size
PY
