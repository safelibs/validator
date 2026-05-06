#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-surfarray-array-red
# @title: Pygame surfarray.array_red extracts the red channel only
# @description: Fills a 2x2 surface with (100, 50, 25) and verifies surfarray.array_red returns a 2x2 array where every entry equals 100.
# @timeout: 120
# @tags: usage, sdl, python, surfarray
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
import pygame.surfarray as sa

pygame.init()
try:
    s = pygame.Surface((2, 2))
    s.fill((100, 50, 25))
    arr = sa.array_red(s)
    assert arr.shape == (2, 2), arr.shape
    assert arr.tolist() == [[100, 100], [100, 100]], arr.tolist()
finally:
    pygame.quit()
PY
