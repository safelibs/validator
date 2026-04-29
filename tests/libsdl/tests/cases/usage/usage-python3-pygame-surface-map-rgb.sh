#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-map-rgb
# @title: pygame surface map rgb
# @description: Exercises pygame surface map rgb through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-map-rgb"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    surface = pygame.Surface((2, 2))
    mapped = surface.map_rgb((12, 34, 56))
    color = surface.unmap_rgb(mapped)
    assert color[:3] == (12, 34, 56)
    print(color[:3])
finally:
    pygame.quit()
PYCASE
