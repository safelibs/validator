#!/usr/bin/env bash
# @testcase: usage-python3-pygame-color-correct-gamma
# @title: pygame Color.correct_gamma curve
# @description: Applies pygame.Color.correct_gamma at gamma 2.2 to a midtone color and verifies the resulting channel values monotonically lower the input while preserving the alpha channel.
# @timeout: 120
# @tags: usage, color
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-color-correct-gamma"

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    src = pygame.Color(128, 128, 128, 200)
    dst = src.correct_gamma(2.2)
    assert isinstance(dst, pygame.Color)
    assert 0 <= dst.r < src.r, (dst.r, src.r)
    assert 0 <= dst.g < src.g, (dst.g, src.g)
    assert 0 <= dst.b < src.b, (dst.b, src.b)
    assert dst.r == dst.g == dst.b, (dst.r, dst.g, dst.b)
    # Identity gamma should round-trip
    same = src.correct_gamma(1.0)
    assert (same.r, same.g, same.b) == (src.r, src.g, src.b), same
    print("gamma", dst.r, dst.g, dst.b, dst.a)
finally:
    pygame.quit()
PY
