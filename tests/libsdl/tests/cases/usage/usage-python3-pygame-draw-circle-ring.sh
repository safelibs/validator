#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-circle-ring
# @title: pygame draw circle width parameter ring
# @description: Draws a circle with a non-zero width to produce a ring on a pygame surface, saves it as BMP, verifies the BM magic bytes, and confirms the centre pixel stays unfilled while the rim pixel is painted.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-circle-ring"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    surface = pygame.Surface((20, 20))
    surface.fill((0, 0, 0))
    pygame.draw.circle(surface, (255, 0, 0), (10, 10), 8, width=2)
    centre = surface.get_at((10, 10))[:3]
    rim = surface.get_at((10, 2))[:3]
    assert centre == (0, 0, 0), centre
    assert rim == (255, 0, 0), rim

    out_path = os.path.join(tmpdir, "ring.bmp")
    pygame.image.save(surface, out_path)
    with open(out_path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM", head
    print("ring", centre, rim)
finally:
    pygame.quit()
PYCASE

grep -l BM "$tmpdir"/ring.bmp >/dev/null
