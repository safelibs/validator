#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-elementwise
# @title: Pygame Vector2 elementwise multiplication
# @description: Multiplies two pygame.math.Vector2 instances component-wise via the elementwise() proxy and verifies each component matches the per-axis product.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-elementwise"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    a = pygame.math.Vector2(2.0, 3.0)
    b = pygame.math.Vector2(5.0, -4.0)

    product = a.elementwise() * b
    assert isinstance(product, pygame.math.Vector2), type(product)
    assert abs(product.x - 10.0) < 1e-9, product.x
    assert abs(product.y - (-12.0)) < 1e-9, product.y

    # Elementwise division should be exact for these values too.
    quotient = a.elementwise() / b
    assert abs(quotient.x - (2.0 / 5.0)) < 1e-9, quotient.x
    assert abs(quotient.y - (3.0 / -4.0)) < 1e-9, quotient.y

    print(case_id, "ok", product, quotient)
finally:
    pygame.quit()
PY
