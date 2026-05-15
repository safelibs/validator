#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r20-time-get-ticks-monotonic-nondecreasing
# @title: Pygame time.get_ticks returns a non-decreasing monotonic millisecond counter
# @description: Calls pygame.time.get_ticks twice with a short pygame.time.delay(20) between, and asserts the second reading is >= the first and the difference is at least 5 ms and at most 5000 ms, confirming SDL-backed millisecond timer is monotonic and roughly tracks wall time.
# @timeout: 60
# @tags: usage, sdl, python, time, monotonic, r20
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
    t0 = pygame.time.get_ticks()
    pygame.time.delay(20)
    t1 = pygame.time.get_ticks()
    assert t1 >= t0, (t0, t1)
    delta = t1 - t0
    assert 5 <= delta <= 5000, delta
    print('ok delta=%d' % delta)
finally:
    pygame.quit()
PY
