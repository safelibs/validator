#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r11-vector2-move-towards
# @title: Pygame Vector2.move_towards advances by fixed step toward target
# @description: Calls Vector2.move_towards from origin toward (10, 0) with step 3 and confirms the result is exactly (3, 0).
# @timeout: 120
# @tags: usage, sdl, python, vector
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
    v = pygame.math.Vector2(0, 0)
    stepped = v.move_towards((10, 0), 3)
    assert stepped == pygame.math.Vector2(3, 0), stepped

    # Stepping past the target stops at the target.
    capped = v.move_towards((4, 0), 100)
    assert capped == pygame.math.Vector2(4, 0), capped
finally:
    pygame.quit()
PY
