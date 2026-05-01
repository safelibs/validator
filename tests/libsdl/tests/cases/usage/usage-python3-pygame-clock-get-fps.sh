#!/usr/bin/env bash
# @testcase: usage-python3-pygame-clock-get-fps
# @title: pygame Clock.get_fps over multiple ticks
# @description: Drives pygame.time.Clock through twelve tick(50) iterations and verifies get_fps returns a finite nonnegative value, get_time stays small and nonnegative, and the cumulative wall time is close to the expected 12 * 20 ms budget.
# @timeout: 120
# @tags: usage, time
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-clock-get-fps"

python3 - <<'PY' "$case_id"
import math
import sys
import time
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    clock = pygame.time.Clock()
    start = time.monotonic()
    for _ in range(12):
        clock.tick(50)
    elapsed_ms = (time.monotonic() - start) * 1000.0

    fps = clock.get_fps()
    assert math.isfinite(fps), fps
    assert fps >= 0.0, fps
    last = clock.get_time()
    assert last >= 0, last
    assert last < 1000, last
    # 12 frames at ~50 fps cap ~ 240 ms; allow generous slack on a busy CI host
    assert elapsed_ms >= 150, elapsed_ms
    assert elapsed_ms < 4000, elapsed_ms
    print("fps", round(fps, 2), last, round(elapsed_ms, 1))
finally:
    pygame.quit()
PY
