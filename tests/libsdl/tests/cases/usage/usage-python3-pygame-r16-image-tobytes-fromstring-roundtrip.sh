#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-image-tobytes-fromstring-roundtrip
# @title: Pygame image.tobytes then image.frombytes round-trips a small RGB Surface
# @description: Builds a 4x3 RGB Surface with a known gradient, calls image.tobytes(surf, "RGB"), reconstructs via image.frombytes(data, (4,3), "RGB"), and asserts the reconstructed Surface get_at values match the original at three sampled pixels.
# @timeout: 120
# @tags: usage, sdl, python, image, bytes
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
    surf = pygame.Surface((4, 3))
    for y in range(3):
        for x in range(4):
            surf.set_at((x, y), (x * 50, y * 60, 120))
    raw = pygame.image.tobytes(surf, 'RGB')
    rebuilt = pygame.image.frombytes(raw, (4, 3), 'RGB')
    for px in [(0, 0), (3, 2), (1, 1)]:
        a = surf.get_at(px)[:3]
        b = rebuilt.get_at(px)[:3]
        assert a == b, (px, a, b)
finally:
    pygame.quit()
PY
