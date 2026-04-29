#!/usr/bin/env bash
# @testcase: usage-python3-pygame-time-wait
# @title: pygame time wait
# @description: Exercises pygame time wait through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-time-wait"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    before = pygame.time.get_ticks()
    pygame.time.wait(5)
    after = pygame.time.get_ticks()
    assert after >= before
    print(after - before)
finally:
    pygame.quit()
PY
