#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-color-grayscale
# @title: Pygame Color.grayscale luminance conversion
# @description: Converts a saturated RGB Color to grayscale via Color.grayscale and verifies the resulting components are equal and within the expected luminance range.
# @timeout: 120
# @tags: usage, sdl, python, color
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
    red = pygame.Color(255, 0, 0)
    gray = red.grayscale()
    # Grayscale produces equal R, G, B components.
    assert gray.r == gray.g == gray.b
    # Red contributes ~30% luminance under common weights; allow a generous range.
    assert 50 < gray.r < 130, gray.r
    # Alpha must be preserved unchanged.
    assert gray.a == red.a

    # Pure white stays white after grayscale conversion.
    white_gray = pygame.Color(255, 255, 255).grayscale()
    assert (white_gray.r, white_gray.g, white_gray.b) == (255, 255, 255)
finally:
    pygame.quit()
PY
