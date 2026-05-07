#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-font-render-produces-surface-with-size
# @title: Pygame font.Font.render returns a Surface whose size matches font.size
# @description: Initializes pygame.font, builds the default Font at size 18, calls font.size('R15') for the expected dimensions and font.render('R15', True, white) for the actual surface, and asserts the rendered surface size matches the size() reading.
# @timeout: 120
# @tags: usage, sdl, python, font
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
    pygame.font.init()
    font = pygame.font.Font(None, 18)
    expected = font.size("R15")
    surf = font.render("R15", True, (255, 255, 255))
    actual = surf.get_size()
    assert expected == actual, (expected, actual)
    assert expected[0] > 0 and expected[1] > 0, expected
finally:
    pygame.quit()
PY
