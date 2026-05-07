#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-webp-info-loop-roundtrip-five
# @title: Pillow animated WEBP loop=5 round-trips through im.info["loop"]
# @description: Saves a 3-frame animated WEBP with loop=5 and re-opens to confirm im.info["loop"] is exactly 5, exercising the libwebpmux loop count round-trip with a non-zero finite repeat count.
# @timeout: 180
# @tags: usage, python3-pil, webp, animation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/loop.webp"
import sys
from PIL import Image
frames = [Image.new('RGB', (16, 16), (40 + 50 * i, 90, 200 - 50 * i)) for i in range(3)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=80, loop=5)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.n_frames == 3, im.n_frames
    assert im.info.get('loop') == 5, im.info.get('loop')
PY
