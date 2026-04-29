#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-outline
# @title: pygame mask outline
# @description: Exercises pygame mask outline through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-outline"
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
    mask = pygame.mask.Mask((4, 4), fill=False)
    mask.set_at((1, 1), 1)
    mask.set_at((2, 1), 1)
    mask.set_at((1, 2), 1)
    mask.set_at((2, 2), 1)
    outline = mask.outline()
    assert len(outline) >= 4
    print(len(outline))
finally:
    pygame.quit()
PYCASE
