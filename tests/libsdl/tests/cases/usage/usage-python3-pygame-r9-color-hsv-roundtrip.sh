#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r9-color-hsv-roundtrip
# @title: Pygame Color HSVA roundtrip
# @description: Constructs a pygame.Color from an RGB triple, sets its hsva property, and verifies the resulting RGB roundtrips within rounding tolerance.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import pygame
pygame.init()
try:
    c = pygame.Color(120, 180, 60)
    h, s, v, a = c.hsva
    # Reassemble a new color from the same hsva and check rgb is close to original.
    d = pygame.Color(0, 0, 0)
    d.hsva = (h, s, v, a)
    for got, want in zip((d.r, d.g, d.b), (120, 180, 60)):
        assert abs(got - want) <= 2, (got, want)
finally:
    pygame.quit()
PY
