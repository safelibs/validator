#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-aapolygon
# @title: pygame draw aapolygon anti-aliased
# @description: Draws an anti-aliased polygon via pygame.draw.aapolygon (or falls back to polygon outline on older pygame), saves it as BMP, verifies the BM magic, and confirms at least one non-background pixel was rendered.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-aapolygon"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    surface = pygame.Surface((32, 32))
    surface.fill((0, 0, 0))
    points = [(4, 4), (28, 6), (16, 28)]
    if hasattr(pygame.draw, "aapolygon"):
        pygame.draw.aapolygon(surface, (255, 255, 255), points)
        used = "aapolygon"
    else:
        pygame.draw.polygon(surface, (255, 255, 255), points, 1)
        used = "polygon"
    found = False
    for x in range(32):
        for y in range(32):
            r, g, b = surface.get_at((x, y))[:3]
            if (r, g, b) != (0, 0, 0):
                found = True
                break
        if found:
            break
    assert found, "expected at least one non-background pixel"
    path = os.path.join(tmpdir, "aapolygon.bmp")
    pygame.image.save(surface, path)
    with open(path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM"
    print("aapolygon", used)
finally:
    pygame.quit()
PY
