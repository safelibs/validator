#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-average-color
# @title: pygame transform average color
# @description: Computes the average color of a uniformly painted pygame surface and verifies the returned RGB tuple matches the fill color.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-average-color"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    surface = pygame.Surface((3, 2))
    surface.fill((40, 80, 120))
    assert pygame.transform.average_color(surface)[:3] == (40, 80, 120)
    print(pygame.transform.average_color(surface)[:3])
finally:
    pygame.quit()
PYCASE
