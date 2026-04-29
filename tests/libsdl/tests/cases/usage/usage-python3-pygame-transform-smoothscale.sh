#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-smoothscale
# @title: Pygame smoothscale transform
# @description: Resizes a Pygame surface with smoothscale and verifies the transformed dimensions.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-smoothscale"
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
    surface = pygame.Surface((8, 6))
    scaled = pygame.transform.smoothscale(surface, (4, 3))
    assert scaled.get_size() == (4, 3)
    print("smoothscale", scaled.get_size())
finally:
    pygame.quit()
PY
