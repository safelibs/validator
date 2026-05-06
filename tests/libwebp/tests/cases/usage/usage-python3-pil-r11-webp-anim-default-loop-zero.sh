#!/usr/bin/env bash
# @testcase: usage-python3-pil-r11-webp-anim-default-loop-zero
# @title: Pillow animated WEBP defaults info["loop"] to 0 (infinite)
# @description: Saves a 3-frame RGB WebP animation without an explicit loop= argument and confirms re-opening reports info["loop"] == 0 and n_frames == 3, exercising the libwebpmux loop-count default.
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

frames = [Image.new('RGB', (8, 8), (50 * i + 10, 100, 150)) for i in range(3)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True,
               append_images=frames[1:], duration=120)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.n_frames == 3, im.n_frames
    assert im.info.get('loop') == 0, im.info.get('loop')
PY
