#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-mask-from-surface
# @title: Pygame mask.from_surface counts opaque pixels
# @description: Builds a translucent surface with a single opaque rectangle and verifies pygame.mask.from_surface produces a mask whose count equals the opaque pixel count.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import pygame
pygame.init()
try:
    surf = pygame.Surface((20, 20), pygame.SRCALPHA)
    surf.fill((0, 0, 0, 0))
    # Paint a 4x5 opaque rectangle.
    for x in range(2, 6):
        for y in range(3, 8):
            surf.set_at((x, y), (255, 0, 0, 255))
    mask = pygame.mask.from_surface(surf)
    n = mask.count()
    assert n == 4 * 5, n
    assert mask.get_size() == (20, 20)
finally:
    pygame.quit()
PY
