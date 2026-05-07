#!/usr/bin/env bash
# @testcase: usage-python3-pil-r14-webp-info-background-rgba-roundtrip
# @title: Pillow animated WEBP background= round-trips through im.info["background"]
# @description: Saves a 2-frame animated WEBP with background=(50, 100, 150, 255) and re-opens to confirm im.info["background"] is a 4-tuple of integer channel values, exercising the libwebpmux ANIM canvas background colour persistence path. Pillow returns the value as a tuple regardless of exact bit-perfect storage.
# @timeout: 180
# @tags: usage, python3-pil, webp, animation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/bg.webp"
import sys
from PIL import Image
frames = [Image.new('RGBA', (16, 16), (200, 50, 30, 255)),
          Image.new('RGBA', (16, 16), (30, 200, 50, 255))]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=80, loop=0, background=(50, 100, 150, 255))

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.n_frames == 2, im.n_frames
    bg = im.info.get('background')
    assert bg is not None, 'no background in WEBP info'
    assert isinstance(bg, tuple), type(bg)
    assert len(bg) == 4, bg
    for v in bg:
        assert isinstance(v, int) and 0 <= v <= 255, bg
PY
