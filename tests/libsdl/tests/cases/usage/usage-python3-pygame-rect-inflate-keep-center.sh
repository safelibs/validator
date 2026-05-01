#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-inflate-keep-center
# @title: Pygame rect inflate keeps center
# @description: Inflates a Pygame Rect by a positive delta and verifies the new size grew while the center stayed put.
# @timeout: 120
# @tags: usage, rect, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-inflate-keep-center"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    base = pygame.Rect(10, 20, 30, 40)
    grown = base.inflate(10, 6)
    assert grown.size == (40, 46)
    assert grown.center == base.center
    shrunk = base.inflate(-10, -10)
    assert shrunk.size == (20, 30)
    assert shrunk.center == base.center
    print("inflate", grown.size, shrunk.size)
finally:
    pygame.quit()
PY
