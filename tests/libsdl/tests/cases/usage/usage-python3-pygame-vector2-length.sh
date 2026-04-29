#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-length
# @title: pygame vector2 length
# @description: Exercises pygame vector2 length through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-length"
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
    value = pygame.math.Vector2(3, 4)
    assert math.isclose(value.length(), 5.0)
    print(value.length())
finally:
    pygame.quit()
PY
