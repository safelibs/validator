#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-copy
# @title: Pygame surface copy
# @description: Copies a Pygame surface and verifies the copied pixel data matches the original.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-copy"
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
    surface = pygame.Surface((4, 4))
    surface.fill((20, 30, 40))
    copied = surface.copy()
    assert copied.get_at((0, 0)) == surface.get_at((0, 0))
    print("copy", copied.get_at((0, 0)))
finally:
    pygame.quit()
PY
