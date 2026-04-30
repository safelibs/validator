#!/usr/bin/env bash
# @testcase: usage-python3-pygame-clock-rawtime-gettime
# @title: pygame Clock get_rawtime and get_time
# @description: Drives a pygame.time.Clock through two ticks separated by a small delay and verifies that get_rawtime and get_time both return non-negative integers and that get_time is at least as large as get_rawtime.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-clock-rawtime-gettime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import sys
import pygame

case_id = sys.argv[1]

pygame.init()
try:
    clock = pygame.time.Clock()
    clock.tick(60)
    pygame.time.delay(5)
    clock.tick(60)
    raw = clock.get_rawtime()
    total = clock.get_time()
    assert isinstance(raw, int), type(raw)
    assert isinstance(total, int), type(total)
    assert raw >= 0, raw
    assert total >= 0, total
    # get_time includes any sleep used to cap the framerate, so it should
    # always be >= the raw frame time.
    assert total >= raw, (total, raw)
    print("clock-times", raw, total)
finally:
    pygame.quit()
PYCASE
