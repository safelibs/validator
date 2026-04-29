#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-dot-product
# @title: pygame Vector2 dot product
# @description: Computes a pygame Vector2 dot product and verifies the expected scalar result.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-dot-product"
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
    value = pygame.math.Vector2(2, 3).dot(pygame.math.Vector2(-1, 4))
    assert value == 10
    print(value)
finally:
    pygame.quit()
PYCASE
