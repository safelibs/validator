#!/usr/bin/env bash
# @testcase: usage-python3-pygame-clock-tick
# @title: Pygame clock tick
# @description: Ticks a Pygame clock and verifies a nonnegative delta value.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-clock-tick"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    clock = pygame.time.Clock()
    delta = clock.tick(60)
    assert delta >= 0
    print("tick", delta)
finally:
    pygame.quit()
PY
