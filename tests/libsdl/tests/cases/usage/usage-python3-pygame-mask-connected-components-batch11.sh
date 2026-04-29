#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-connected-components-batch11
# @title: pygame mask connected components
# @description: Splits separated set pixels into connected components with pygame mask helpers.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-connected-components-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    mask = pygame.mask.Mask((4, 4), fill=False)
    mask.set_at((1, 1), 1)
    mask.set_at((3, 3), 1)
    components = mask.connected_components()
    assert len(components) == 2
    assert sorted(component.count() for component in components) == [1, 1]
    print('mask-components')
finally:
    pygame.quit()
PYCASE
