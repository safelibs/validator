#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-surface-get-bitsize-rgba-32
# @title: Pygame Surface with SRCALPHA flag reports 32-bit pixel depth
# @description: Constructs pygame.Surface((4, 4), pygame.SRCALPHA), and asserts get_bitsize() returns 32 and get_bytesize() returns 4, confirming SDL-backed per-pixel alpha surfaces default to a 32-bit ARGB/RGBA pixel format.
# @timeout: 60
# @tags: usage, sdl, python, surface, bitsize, r20
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
    s = pygame.Surface((4, 4), pygame.SRCALPHA)
    bs = s.get_bitsize()
    by = s.get_bytesize()
    assert bs == 32, bs
    assert by == 4, by
    print('ok bitsize=%d bytesize=%d' % (bs, by))
finally:
    pygame.quit()
PY
