#!/usr/bin/env bash
# @testcase: usage-python3-pygame-draw-aacircle
# @title: pygame draw aacircle anti-aliased
# @description: Draws an anti-aliased circle via pygame.draw.aacircle (or falls back to circle on older pygame), saves the surface as BMP, verifies the BM magic, and confirms a non-background pixel exists on the rim.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-draw-aacircle"
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
    draw_fn = getattr(pygame.draw, "aacircle", pygame.draw.circle)
    draw_fn(surface, (255, 255, 255), (16, 16), 10)
    found = False
    for x in range(32):
        for y in range(32):
            r, g, b = surface.get_at((x, y))[:3]
            if (r, g, b) != (0, 0, 0):
                found = True
                break
        if found:
            break
    assert found, "expected at least one non-background pixel on the rim"
    path = os.path.join(tmpdir, "aacircle.bmp")
    pygame.image.save(surface, path)
    with open(path, "rb") as fh:
        head = fh.read(2)
    assert head == b"BM"
    print("aacircle", draw_fn.__name__)
finally:
    pygame.quit()
PY
