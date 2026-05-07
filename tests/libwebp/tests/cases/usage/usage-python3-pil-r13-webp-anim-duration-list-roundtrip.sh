#!/usr/bin/env bash
# @testcase: usage-python3-pil-r13-webp-anim-duration-list-roundtrip
# @title: Pillow animated WEBP with per-frame duration list reports matching frame count
# @description: Saves a 3-frame animated WEBP with a per-frame duration list ([60, 120, 180]) and verifies n_frames is 3 on read-back and the file decodes with a non-zero info["duration"] per frame, exercising the libwebpmux per-frame duration list path.
# @timeout: 180
# @tags: usage, python3-pil, webp, animation
# @client: python3-pil

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/dur.webp"
import sys
from PIL import Image

frames = [Image.new('RGB', (12, 12), (40 + 60 * i, 100, 220 - 60 * i)) for i in range(3)]
frames[0].save(sys.argv[1], 'WEBP', save_all=True, append_images=frames[1:],
               duration=[60, 120, 180], loop=0)

with Image.open(sys.argv[1]) as im:
    im.load()
    assert im.format == 'WEBP', im.format
    assert im.n_frames == 3, im.n_frames

    # Walk all frames and ensure each reports a duration > 0.
    durations = []
    for n in range(im.n_frames):
        im.seek(n)
        im.load()
        durations.append(int(im.info.get('duration', 0)))
    assert all(d > 0 for d in durations), durations
PY
