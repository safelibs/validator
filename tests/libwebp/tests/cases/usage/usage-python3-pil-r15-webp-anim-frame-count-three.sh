#!/usr/bin/env bash
# @testcase: usage-python3-pil-r15-webp-anim-frame-count-three
# @title: Pillow animated WEBP with three frames reports n_frames == 3 and is_animated == True
# @description: Saves a 3-frame animated RGB WEBP via Pillow's save_all/append_images and re-opens to confirm im.n_frames is exactly 3 and im.is_animated is True, exercising the libwebpmux animation chunk count round-trip.
# @timeout: 180
# @tags: usage, python3-pil, webp, animation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/anim.webp"
import sys
from PIL import Image
frames = [Image.new('RGB', (16, 16), (40 + 50 * i, 90, 200 - 50 * i)) for i in range(3)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=80, loop=0)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.n_frames == 3, im.n_frames
    assert im.is_animated is True, im.is_animated
PY
