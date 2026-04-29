#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-scale2x
# @title: pygame transform scale2x
# @description: Exercises pygame transform scale2x through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-scale2x"
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
    surface = pygame.Surface((3, 2))
    out = pygame.transform.scale2x(surface)
    assert out.get_size() == (6, 4)
    print(out.get_size())
finally:
    pygame.quit()
PY
