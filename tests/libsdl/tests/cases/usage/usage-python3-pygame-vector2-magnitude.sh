#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-magnitude
# @title: pygame Vector2 magnitude
# @description: Computes the magnitude and length of a pygame Vector2(3, 4) and verifies both methods return five.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-magnitude"
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
    vec = pygame.math.Vector2(3, 4)
    assert abs(vec.magnitude() - 5.0) < 1e-6
    assert abs(vec.length() - 5.0) < 1e-6
    print("magnitude", vec.magnitude())
finally:
    pygame.quit()
PY
