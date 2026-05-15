#!/usr/bin/env bash
# @testcase: usage-python3-pil-r19-webp-tell-after-seek-zero
# @title: Pillow tell() reports 0 after seek(0) on an animated WEBP and 2 after seek(2)
# @description: Saves a four-frame animated WEBP via Pillow, reopens it, seeks to frame 2 and asserts tell()==2, then seeks back to 0 and asserts tell()==0 — pinning the libwebp animation seek-and-tell semantics.
# @timeout: 120
# @tags: usage, python3-pil, webp, seek-tell, r19
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/anim.webp" <<'PY'
import sys
from PIL import Image

frames = []
for f in range(4):
    img = Image.new('RGB', (24, 24), ((f * 60) & 0xff, 100, 200 - f * 40))
    frames.append(img)

frames[0].save(
    sys.argv[1], 'WEBP',
    save_all=True, append_images=frames[1:],
    duration=100, loop=0, quality=75,
)

with Image.open(sys.argv[1]) as out:
    out.load()
    assert out.n_frames == 4, out.n_frames
    out.seek(2)
    assert out.tell() == 2, out.tell()
    out.seek(0)
    assert out.tell() == 0, out.tell()
PY
