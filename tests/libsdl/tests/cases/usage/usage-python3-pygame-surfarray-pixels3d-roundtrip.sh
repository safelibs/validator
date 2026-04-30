#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surfarray-pixels3d-roundtrip
# @title: pygame surfarray.pixels3d numpy roundtrip
# @description: Locks a pygame surface through surfarray.pixels3d, mutates pixels via numpy slicing, then reads the values back through Surface.get_at to confirm the in-place edit landed and saves the result as BMP.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surfarray-pixels3d-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame
import pygame.surfarray as surfarray

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    surface = pygame.Surface((4, 3))
    surface.fill((0, 0, 0))
    view = surfarray.pixels3d(surface)
    assert view.shape[:2] == (4, 3), view.shape
    view[1, 2] = (200, 100, 50)
    view[3, 0] = (10, 220, 30)
    del view

    px_a = surface.get_at((1, 2))[:3]
    px_b = surface.get_at((3, 0))[:3]
    assert px_a == (200, 100, 50), px_a
    assert px_b == (10, 220, 30), px_b

    out_path = os.path.join(tmpdir, "pixels3d.bmp")
    pygame.image.save(surface, out_path)
    with open(out_path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM", head
    print("pixels3d", px_a, px_b)
finally:
    pygame.quit()
PYCASE

grep -l BM "$tmpdir"/pixels3d.bmp >/dev/null
