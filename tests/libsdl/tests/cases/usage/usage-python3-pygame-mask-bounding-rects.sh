#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-bounding-rects
# @title: pygame mask bounding rects
# @description: Builds a pygame mask with a small connected region and verifies get_bounding_rects returns at least one bounding rectangle of nonzero width.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-bounding-rects"
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
    mask = pygame.mask.Mask((4, 4), fill=False)
    mask.set_at((1, 1), 1)
    mask.set_at((1, 2), 1)
    rects = mask.get_bounding_rects()
    assert len(rects) >= 1
    assert rects[0].width >= 1
    print("rects", len(rects))
finally:
    pygame.quit()
PY
