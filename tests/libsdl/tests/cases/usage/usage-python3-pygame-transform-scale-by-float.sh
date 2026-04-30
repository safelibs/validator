#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-scale-by-float
# @title: Pygame transform scale_by float factor
# @description: Scales a Pygame surface using pygame.transform.scale_by with a float factor and verifies the resulting integer dimensions.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-scale-by-float"
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
    surface = pygame.Surface((10, 4))
    scaled = pygame.transform.scale_by(surface, 1.5)
    assert scaled.get_size() == (15, 6), scaled.get_size()
    print("scale_by", scaled.get_size())
finally:
    pygame.quit()
PY
