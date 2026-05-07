#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-image-frombuffer-roundtrip
# @title: Pygame image.frombuffer round-trips bytes back to the original pixels
# @description: Builds a 2x2 RGB byte buffer, constructs a Surface via pygame.image.frombuffer, and asserts each pixel reads back to the matching RGB triple.
# @timeout: 120
# @tags: usage, sdl, python, image
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame

pygame.init()
try:
    pixels = bytes([
        255, 0, 0,    0, 255, 0,
        0, 0, 255,    255, 255, 0,
    ])
    surf = pygame.image.frombuffer(pixels, (2, 2), "RGB")
    assert surf.get_size() == (2, 2)
    assert surf.get_at((0, 0))[:3] == (255, 0, 0)
    assert surf.get_at((1, 0))[:3] == (0, 255, 0)
    assert surf.get_at((0, 1))[:3] == (0, 0, 255)
    assert surf.get_at((1, 1))[:3] == (255, 255, 0)
finally:
    pygame.quit()
PY
