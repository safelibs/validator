#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mask-count-tenth
# @title: pygame mask count tenth
# @description: Sets two pixels on a pygame mask in the tenth batch and verifies mask.count returns the exact number of set bits.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mask-count-tenth"
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
    mask = pygame.mask.Mask((4, 3), fill=False)
    mask.set_at((1, 2), 1)
    mask.set_at((3, 0), 1)
    assert mask.count() == 2
    print("count", mask.count())
finally:
    pygame.quit()
PY
