#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-transform-scale-target-size
# @title: Pygame transform.scale produces a surface with the requested target size
# @description: Calls pygame.transform.scale on a 4x4 surface to (16, 8) and asserts the returned surface get_size matches the target dimensions.
# @timeout: 120
# @tags: usage, sdl, python, transform
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
    src = pygame.Surface((4, 4))
    src.fill((40, 80, 160))
    out = pygame.transform.scale(src, (16, 8))
    assert out.get_size() == (16, 8), out.get_size()
    r, g, b, _ = out.get_at((8, 4))
    assert (r, g, b) == (40, 80, 160), (r, g, b)
finally:
    pygame.quit()
PY
