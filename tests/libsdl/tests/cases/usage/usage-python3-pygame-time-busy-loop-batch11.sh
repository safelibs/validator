#!/usr/bin/env bash
# @testcase: usage-python3-pygame-time-busy-loop-batch11
# @title: pygame clock busy loop
# @description: Ticks a pygame Clock with tick_busy_loop under the dummy SDL drivers.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-time-busy-loop-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    clock = pygame.time.Clock()
    elapsed = clock.tick_busy_loop(120)
    assert elapsed >= 0
    print('busy', elapsed)
finally:
    pygame.quit()
PYCASE
