#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-time-clock-tick
# @title: Pygame Clock.tick reports elapsed ms
# @description: Calls pygame.time.Clock().tick() across two frames and verifies the returned millisecond delta is a non-negative integer.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import pygame
pygame.init()
try:
    clock = pygame.time.Clock()
    clock.tick()
    # Throttle to 200 fps (5ms target) and ensure tick returns a non-negative int.
    delta = clock.tick(200)
    assert isinstance(delta, int)
    assert delta >= 0
    fps = clock.get_fps()
    assert fps >= 0
finally:
    pygame.quit()
PY
