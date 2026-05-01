#!/usr/bin/env bash
# @testcase: usage-python3-pygame-color-hsv-roundtrip
# @title: Pygame Color HSV round trip
# @description: Reads the hsva attribute of a known RGB color and round trips through hsva assignment to verify the resulting RGB stays close to the original.
# @timeout: 120
# @tags: usage, color, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-color-hsv-roundtrip"
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
    red = pygame.Color(255, 0, 0)
    h, s, v, a = red.hsva
    assert abs(h - 0.0) < 1e-6
    assert abs(s - 100.0) < 1e-6
    assert abs(v - 100.0) < 1e-6
    assert abs(a - 100.0) < 1e-6

    blue = pygame.Color(0, 0, 0)
    blue.hsva = (240.0, 100.0, 100.0, 100.0)
    assert blue.r == 0 and blue.g == 0 and blue.b == 255
    assert blue.a == 255

    green = pygame.Color(0, 255, 0)
    gh, gs, gv, ga = green.hsva
    round_trip = pygame.Color(0, 0, 0)
    round_trip.hsva = (gh, gs, gv, ga)
    assert (round_trip.r, round_trip.g, round_trip.b) == (0, 255, 0)
    print("hsva", red.hsva, blue.r, blue.g, blue.b)
finally:
    pygame.quit()
PY
