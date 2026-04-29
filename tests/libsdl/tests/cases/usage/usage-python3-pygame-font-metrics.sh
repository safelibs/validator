#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-metrics
# @title: Pygame font metrics
# @description: Loads the default Pygame font and verifies metrics for rendered text.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-font-metrics"
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
    pygame.font.init()
    font = pygame.font.Font(None, 18)
    metrics = font.metrics("abc")
    assert len(metrics) == 3 and all(item is not None for item in metrics)
    print("metrics", len(metrics))
finally:
    pygame.quit()
PY
