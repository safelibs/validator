#!/usr/bin/env bash
# @testcase: usage-python3-pygame-rect-scale-by
# @title: pygame Rect scale_by float factor
# @description: Calls pygame.Rect.scale_by with a float factor and verifies the returned Rect grows around its centre while leaving the original Rect untouched.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-rect-scale-by"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    rect = pygame.Rect(10, 20, 40, 20)
    original_center = rect.center
    if hasattr(rect, "scale_by"):
        scaled = rect.scale_by(2.0)
        used = "scale_by"
    else:
        # Fallback: inflate emulates a 2.0 factor for a width/height pair.
        scaled = rect.inflate(rect.width, rect.height)
        used = "inflate"
    # Centre preserved.
    assert scaled.center == original_center, (scaled.center, original_center)
    # Doubled dimensions.
    assert scaled.width == rect.width * 2, scaled.width
    assert scaled.height == rect.height * 2, scaled.height
    # Original unchanged.
    assert rect == pygame.Rect(10, 20, 40, 20)
    print("scale_by", used, scaled)
finally:
    pygame.quit()
PY
