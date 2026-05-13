#!/usr/bin/env bash
# @testcase: usage-python3-pil-r16-webp-save-all-animation-duration
# @title: Pillow save_all=True with three frames and explicit duration produces an animated WebP that opens with n_frames==3
# @description: Builds three distinct RGB frames in memory, saves them with Pillow as a single animated WebP via save_all=True/append_images/duration=80, then re-opens the file and asserts n_frames==3, is_animated is True, and the per-image duration is reported as 80ms.
# @timeout: 120
# @tags: usage, python3-pil, webp, animation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/anim.webp" <<'PY'
import sys
from PIL import Image

frames = [
    Image.new('RGB', (32, 24), (200, 30, 30)),
    Image.new('RGB', (32, 24), (30, 200, 30)),
    Image.new('RGB', (32, 24), (30, 30, 200)),
]
frames[0].save(
    sys.argv[1],
    'WEBP',
    save_all=True,
    append_images=frames[1:],
    duration=80,
    loop=0,
)

with Image.open(sys.argv[1]) as im:
    assert getattr(im, 'is_animated', False), 'expected is_animated'
    assert im.n_frames == 3, im.n_frames
    im.seek(1)
    assert im.info.get('duration') == 80, im.info.get('duration')
PY
