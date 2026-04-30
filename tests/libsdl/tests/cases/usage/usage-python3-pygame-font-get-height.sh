#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-get-height
# @title: pygame Font get_height for default font
# @description: Initialises pygame.font with the default SysFont, queries Font.get_height(), and verifies it is a positive integer not smaller than the linesize-derived ascent.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-font-get-height"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
pygame.font.init()
try:
    font = pygame.font.Font(None, 18)
    height = font.get_height()
    ascent = font.get_ascent()
    linesize = font.get_linesize()
    assert isinstance(height, int)
    assert height > 0, f"expected positive height, got {height}"
    assert linesize >= height, f"linesize {linesize} should be >= height {height}"
    assert ascent <= height, f"ascent {ascent} should be <= height {height}"
    print("get_height", height, "ascent", ascent, "linesize", linesize)
finally:
    pygame.font.quit()
    pygame.quit()
PY
