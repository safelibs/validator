#!/usr/bin/env bash
# @testcase: usage-python3-pil-webp-n-frames-vs-is-animated
# @title: Pillow WebP n_frames vs is_animated discrimination
# @description: Saves a still and an animated WebP through Pillow and verifies that Image.open reports is_animated=False with n_frames==1 for the still file and is_animated=True with n_frames>1 for the animated file.
# @timeout: 180
# @tags: usage, webp, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pil-webp-n-frames-vs-is-animated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
from pathlib import Path
from PIL import Image
import sys

case_id = sys.argv[1]
tmpdir = Path(sys.argv[2])

# Still WebP.
still = tmpdir / 'still.webp'
Image.new('RGB', (6, 5), (10, 20, 30)).save(still, 'WEBP', lossless=True)

# Animated WebP.
anim = tmpdir / 'anim.webp'
frames = [Image.new('RGB', (6, 5), c) for c in ((200, 0, 0), (0, 200, 0), (0, 0, 200))]
frames[0].save(anim, 'WEBP', save_all=True, append_images=frames[1:],
               duration=60, loop=0, lossless=True)

with Image.open(still) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'is_animated', False) is False, im.is_animated
    assert im.n_frames == 1, im.n_frames

with Image.open(anim) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'is_animated', False) is True, im.is_animated
    assert im.n_frames == 3, im.n_frames

print('still=1 anim=3')
PYCASE
