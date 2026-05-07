#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r14-image-tostring-frombuffer-roundtrip
# @title: Pygame image.tostring + image.frombuffer round-trip preserves RGB pixels
# @description: Builds a 3x2 surface with distinct per-pixel colours, exports it via pygame.image.tostring(format='RGB'), reconstructs a new surface via pygame.image.frombuffer with the same size and format, and asserts each pixel of the reconstructed surface matches the source pixel byte-for-byte.
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
    src = pygame.Surface((3, 2))
    pixels = [
        (10, 20, 30), (40, 50, 60), (70, 80, 90),
        (100, 110, 120), (130, 140, 150), (160, 170, 180),
    ]
    for i, c in enumerate(pixels):
        src.set_at((i % 3, i // 3), c)
    raw = pygame.image.tostring(src, "RGB")
    rebuilt = pygame.image.frombuffer(raw, (3, 2), "RGB")
    for i, c in enumerate(pixels):
        x, y = i % 3, i // 3
        assert rebuilt.get_at((x, y))[:3] == c, (x, y, rebuilt.get_at((x, y))[:3], c)
finally:
    pygame.quit()
PY
