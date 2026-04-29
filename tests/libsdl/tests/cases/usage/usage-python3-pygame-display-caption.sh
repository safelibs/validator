#!/usr/bin/env bash
# @testcase: usage-python3-pygame-display-caption
# @title: pygame display caption
# @description: Exercises pygame display caption through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-display-caption"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    pygame.display.set_mode((4, 4))
    pygame.display.set_caption('validator-caption')
    assert pygame.display.get_caption()[0] == 'validator-caption'
    print(pygame.display.get_caption()[0])
finally:
    pygame.quit()
PY
