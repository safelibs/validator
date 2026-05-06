#!/usr/bin/env bash
# @testcase: usage-python3-pil-r10-webp-info-loop-key
# @title: Pillow WebP animation info exposes loop count
# @description: Saves a 3-frame animated WebP with loop=2 via Pillow, reopens it, and asserts the info dict reports loop == 2 and is_animated is True.
# @timeout: 180
# @tags: usage, python3-pil, webp
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/anim.webp"
import sys
from PIL import Image
frames = [Image.new('RGBA', (24, 24), (255 * (i % 2), 50, 200, 255)) for i in range(3)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=80, loop=2, lossless=True)
PY

python3 - <<'PY' "$tmpdir/anim.webp"
import sys
from PIL import Image
with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert getattr(im, 'is_animated', False), 'expected animated webp'
    assert im.info.get('loop') == 2, im.info.get('loop')
    assert im.n_frames == 3, im.n_frames
print('ok')
PY
