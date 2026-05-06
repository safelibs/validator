#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-mask-overlap-area
# @title: Pygame mask overlap_area counts intersection
# @description: Builds two pygame.mask.Mask objects and verifies overlap_area on a known offset returns the expected pixel count.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import pygame
pygame.init()
try:
    a = pygame.Mask((10, 10), fill=True)
    b = pygame.Mask((10, 10), fill=True)
    # Offset b by (2, 3) -> overlap is (10-2)*(10-3) = 8*7 = 56.
    n = a.overlap_area(b, (2, 3))
    assert n == 56, n
    # No overlap when offset entirely off.
    assert a.overlap_area(b, (10, 0)) == 0
finally:
    pygame.quit()
PY
