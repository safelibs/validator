#!/usr/bin/env bash
# @testcase: usage-python3-pil-r12-webp-anim-explicit-loop-three
# @title: Pillow animated WEBP with loop=3 preserves the loop count on read-back
# @description: Saves a 2-frame WEBP animation with an explicit loop=3 argument and confirms reopening reports im.info["loop"] == 3 and n_frames == 2, exercising the libwebpmux loop-count round-trip.
# @timeout: 180
# @tags: usage, python3-pil, webp, animation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/loop3.webp"
import sys
from PIL import Image

frames = [Image.new('RGB', (8, 8), (50, 80, 120)),
          Image.new('RGB', (8, 8), (200, 80, 50))]
frames[0].save(sys.argv[1], 'WEBP', save_all=True,
               append_images=frames[1:], duration=100, loop=3)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.n_frames == 2, im.n_frames
    assert im.info.get('loop') == 3, im.info.get('loop')
PY
