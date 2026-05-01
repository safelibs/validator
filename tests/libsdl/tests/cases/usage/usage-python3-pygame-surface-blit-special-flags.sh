#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-blit-special-flags
# @title: pygame Surface.blit BLEND_RGBA_MULT mode
# @description: Blits a half-intensity gray surface onto a colored destination using the BLEND_RGBA_MULT special flag and verifies each output channel equals the integer-divided product of source and destination per pygame multiply blend semantics.
# @timeout: 120
# @tags: usage, surface
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-surface-blit-special-flags"

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    dst = pygame.Surface((4, 4))
    dst.fill((200, 100, 40))

    src = pygame.Surface((4, 4))
    src.fill((128, 128, 128, 255))

    dst.blit(src, (0, 0), special_flags=pygame.BLEND_RGBA_MULT)

    px = dst.get_at((1, 1))
    # Pygame multiply blend: (a * b) // 256 (or close enough)
    expected_r = (200 * 128) // 256
    expected_g = (100 * 128) // 256
    expected_b = (40 * 128) // 256
    assert abs(px.r - expected_r) <= 1, (px.r, expected_r)
    assert abs(px.g - expected_g) <= 1, (px.g, expected_g)
    assert abs(px.b - expected_b) <= 1, (px.b, expected_b)
    # Multiplying any channel by a smaller-than-255 factor must dim it
    assert px.r < 200 and px.g < 100 and px.b < 40
    print("mult", tuple(px)[:3])
finally:
    pygame.quit()
PY
