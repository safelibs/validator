#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-image-tostring-rgb-length-matches
# @title: Pygame image.tostring with RGB format yields w*h*3 bytes
# @description: Builds an 8x6 Surface, calls pygame.image.tostring(surf, "RGB"), and asserts the byte length equals 8*6*3 — pinning the SDL-backed pixel serialisation length contract for the RGB format.
# @timeout: 60
# @tags: usage, sdl, python, image, tostring, r18
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
    W, H = 8, 6
    s = pygame.Surface((W, H))
    s.fill((10, 20, 30))
    buf = pygame.image.tostring(s, "RGB")
    assert isinstance(buf, (bytes, bytearray)), type(buf)
    assert len(buf) == W * H * 3, len(buf)
finally:
    pygame.quit()
PY
