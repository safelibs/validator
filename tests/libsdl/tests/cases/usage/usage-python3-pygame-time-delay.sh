#!/usr/bin/env bash
# @testcase: usage-python3-pygame-time-delay
# @title: Pygame time delay
# @description: Runs a short Pygame time delay and verifies elapsed ticks are monotonic.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-time-delay"
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
    before = pygame.time.get_ticks()
    pygame.time.delay(5)
    after = pygame.time.get_ticks()
    assert after >= before
    print("delay", after - before)
finally:
    pygame.quit()
PY
