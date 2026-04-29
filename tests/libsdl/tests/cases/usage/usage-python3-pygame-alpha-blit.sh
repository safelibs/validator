#!/usr/bin/env bash
# @testcase: usage-python3-pygame-alpha-blit
# @title: Pygame alpha blit
# @description: Blits an alpha surface onto another surface and checks the resulting pixel alpha.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-alpha-blit"
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
    base = pygame.Surface((4, 4), pygame.SRCALPHA)
    overlay = pygame.Surface((4, 4), pygame.SRCALPHA)
    overlay.fill((255, 0, 0, 128))
    base.blit(overlay, (0, 0))
    assert base.get_at((1, 1)).a == 128
    print("alpha", base.get_at((1, 1)).a)
finally:
    pygame.quit()
PY
