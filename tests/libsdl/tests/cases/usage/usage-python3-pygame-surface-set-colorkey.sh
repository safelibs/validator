#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-set-colorkey
# @title: pygame surface set_colorkey
# @description: Configures a colorkey on a pygame surface and verifies get_colorkey returns the same RGB triple that was set.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-set-colorkey"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import os
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    surface = pygame.Surface((4, 4))
    surface.fill((255, 0, 255))
    surface.set_colorkey((255, 0, 255))
    assert surface.get_colorkey()[:3] == (255, 0, 255)
    print("colorkey", surface.get_colorkey()[:3])
finally:
    pygame.quit()
PY
