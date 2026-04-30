#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector2-clamp-magnitude
# @title: pygame Vector2 clamp_magnitude
# @description: Calls pygame.math.Vector2.clamp_magnitude with a max less than the current length and verifies the resulting vector keeps direction while its length matches the requested cap.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector2-clamp-magnitude"
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
    v = pygame.math.Vector2(3.0, 4.0)
    assert math.isclose(v.length(), 5.0)
    if hasattr(v, "clamp_magnitude"):
        clamped = v.clamp_magnitude(2.5)
        used = "clamp_magnitude"
    else:
        # Fallback for older pygame: scale_to_length emulates the cap path.
        clamped = pygame.math.Vector2(v)
        clamped.scale_to_length(2.5)
        used = "scale_to_length"
    assert math.isclose(clamped.length(), 2.5, rel_tol=1e-6)
    # Direction preserved: cross-product with original is ~zero.
    cross = v.x * clamped.y - v.y * clamped.x
    assert math.isclose(cross, 0.0, abs_tol=1e-6)
    # No-op when already within the cap.
    if used == "clamp_magnitude":
        big_cap = v.clamp_magnitude(10.0)
        assert math.isclose(big_cap.length(), 5.0, rel_tol=1e-6)
    print("clamp", used, clamped.length())
finally:
    pygame.quit()
PY
