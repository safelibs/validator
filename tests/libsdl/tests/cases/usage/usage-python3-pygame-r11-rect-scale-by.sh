#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-rect-scale-by
# @title: Pygame Rect.scale_by doubles dimensions while keeping center
# @description: Calls Rect.scale_by(2.0) and verifies the returned rect has doubled width/height while preserving the original center.
# @timeout: 120
# @tags: usage, sdl, python, rect
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
    r = pygame.Rect(10, 10, 40, 20)
    s = r.scale_by(2.0)
    assert s.width == 80, s.width
    assert s.height == 40, s.height
    assert s.center == r.center, (s.center, r.center)
finally:
    pygame.quit()
PY
