#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-invert
# @title: Pygame PixelArray inversion preserves dimensions and inverts pixel values
# @description: Inverts every pixel of a Surface via pygame.PixelArray indexing (255 - r, 255 - g, 255 - b) since pygame 2.5 has no transform.invert; verifies the result has the same dimensions, the originally bright (240, 240, 240) pixel becomes (15, 15, 15) within tolerance, and a black pixel becomes (255, 255, 255).
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-invert"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    src = pygame.Surface((16, 16))
    src.fill((0, 0, 0))
    src.set_at((8, 8), (240, 240, 240))
    src.set_at((0, 0), (0, 0, 0))

    inverted = src.copy()
    pa = pygame.PixelArray(inverted)
    try:
        for y in range(inverted.get_height()):
            for x in range(inverted.get_width()):
                colour = inverted.unmap_rgb(pa[x, y])
                pa[x, y] = (255 - colour.r, 255 - colour.g, 255 - colour.b)
    finally:
        del pa

    assert inverted.get_size() == (16, 16), inverted.get_size()

    bright_in = inverted.get_at((8, 8))
    assert (bright_in.r, bright_in.g, bright_in.b) == (15, 15, 15), bright_in
    black_in = inverted.get_at((0, 0))
    assert (black_in.r, black_in.g, black_in.b) == (255, 255, 255), black_in

    # Original surface must not have been mutated.
    orig = src.get_at((8, 8))
    assert (orig.r, orig.g, orig.b) == (240, 240, 240), (orig.r, orig.g, orig.b)
    print(case_id, "ok", bright_in.r, black_in.r)
finally:
    pygame.quit()
PY
