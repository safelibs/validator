#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-centroid
# @title: pygame mask centroid
# @description: Marks a single opaque pixel in a pygame mask and verifies mask.centroid reports its exact coordinates.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-centroid"
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
    mask = pygame.mask.Mask((5, 4), fill=False)
    mask.set_at((2, 1), 1)
    assert mask.centroid() == (2, 1)
    print(mask.centroid())
finally:
    pygame.quit()
PYCASE
