#!/usr/bin/env bash
# @testcase: usage-python3-pygame-color-tuple-iter
# @title: pygame Color tuple/iter conversion
# @description: Iterates a pygame.Color directly, converts it to tuple/list, and indexes channels by position to verify the RGBA sequence interface matches the named attributes.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-color-tuple-iter"
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
    color = pygame.Color(10, 20, 30, 40)
    # Iteration order is r, g, b, a.
    iterated = list(iter(color))
    assert iterated == [10, 20, 30, 40], iterated
    # tuple()/list() should both yield the same 4-element form.
    assert tuple(color) == (10, 20, 30, 40), tuple(color)
    assert list(color) == [10, 20, 30, 40], list(color)
    # Indexing must agree with named attributes.
    assert color[0] == color.r == 10
    assert color[1] == color.g == 20
    assert color[2] == color.b == 30
    assert color[3] == color.a == 40
    assert len(color) == 4, len(color)
    print("color-iter", iterated)
finally:
    pygame.quit()
PY
