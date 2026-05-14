#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r18-time-clock-tick-returns-nonneg-ms
# @title: Pygame time.Clock.tick returns a non-negative millisecond delta
# @description: Constructs a pygame.time.Clock and asserts the first tick(60) call returns a non-negative integer milliseconds-since-last-tick value, pinning the SDL-backed timer contract.
# @timeout: 60
# @tags: usage, sdl, python, time, clock, r18
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
    clk = pygame.time.Clock()
    dt = clk.tick(60)
    assert isinstance(dt, int), type(dt)
    assert dt >= 0, dt
finally:
    pygame.quit()
PY
