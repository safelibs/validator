#!/usr/bin/env bash
# @testcase: usage-python3-pil-r9-tiff-multipage-frame-count
# @title: Pillow multi-page TIFF n_frames matches save count
# @description: Saves a 5-frame multi-page TIFF via Pillow append_images and verifies n_frames reports 5 on reopen.
# @timeout: 180
# @tags: usage, tiff, python
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/multi.tiff" <<'PY'
import sys
from PIL import Image
frames = [Image.new("L", (4, 4), (i * 30) & 0xff) for i in range(5)]
frames[0].save(sys.argv[1], save_all=True, append_images=frames[1:], compression="raw")

with Image.open(sys.argv[1]) as ro:
    assert getattr(ro, "n_frames", None) == 5, ro.n_frames
    seen = []
    for i in range(ro.n_frames):
        ro.seek(i)
        ro.load()
        seen.append(ro.size)
    assert seen == [(4, 4)] * 5, seen
PY
