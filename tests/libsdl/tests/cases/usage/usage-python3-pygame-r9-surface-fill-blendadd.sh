#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-surface-fill-blendadd
# @title: Pygame Surface.fill BLEND_ADD saturates
# @description: Fills a surface initialized with (100, 50, 25) using BLEND_ADD with (10, 60, 250) and verifies channel-wise additive saturation behaves as expected.
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
    surf = pygame.Surface((4, 4))
    surf.fill((100, 50, 25))
    surf.fill((10, 60, 250), special_flags=pygame.BLEND_ADD)
    r, g, b = tuple(surf.get_at((1, 1)))[:3]
    assert (r, g, b) == (110, 110, 255), (r, g, b)
finally:
    pygame.quit()
PY
