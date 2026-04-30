#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-polygon-outline
# @title: pygame draw polygon filled vs outline
# @description: Draws the same triangle once filled (width=0) and once as an outline (width=1) on separate pygame surfaces, asserts that the filled surface paints its interior pixel while the outline-only surface leaves it unfilled but paints an edge pixel, and saves the outline result as BMP with BM magic verified.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-polygon-outline"
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

points = [(2, 14), (8, 2), (14, 14)]
interior = (8, 10)

pygame.init()
try:
    filled = pygame.Surface((16, 16))
    filled.fill((0, 0, 0))
    pygame.draw.polygon(filled, (255, 0, 0), points, 0)
    assert filled.get_at(interior)[:3] == (255, 0, 0), filled.get_at(interior)

    outline = pygame.Surface((16, 16))
    outline.fill((0, 0, 0))
    pygame.draw.polygon(outline, (0, 255, 0), points, 1)
    assert outline.get_at(interior)[:3] == (0, 0, 0), outline.get_at(interior)
    edge_painted = sum(
        1
        for y in range(outline.get_height())
        for x in range(outline.get_width())
        if outline.get_at((x, y))[:3] == (0, 255, 0)
    )
    assert edge_painted > 0, edge_painted

    out_path = os.path.join(tmpdir, "outline.bmp")
    pygame.image.save(outline, out_path)
    with open(out_path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM", head
    print("polygon-outline", edge_painted)
finally:
    pygame.quit()
PYCASE

grep -l BM "$tmpdir"/outline.bmp >/dev/null
