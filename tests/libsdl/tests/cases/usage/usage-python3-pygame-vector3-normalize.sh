#!/usr/bin/env bash
# @testcase: usage-python3-pygame-vector3-normalize
# @title: Pygame Vector3 normalize
# @description: Normalizes a pygame.math.Vector3 and verifies the result has unit length while the original vector is left unchanged.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-vector3-normalize"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import math
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.init()
try:
    v = pygame.math.Vector3(3.0, 0.0, 4.0)
    assert abs(v.length() - 5.0) < 1e-9, v.length()

    n = v.normalize()
    assert isinstance(n, pygame.math.Vector3), type(n)
    assert abs(n.length() - 1.0) < 1e-9, n.length()
    assert abs(n.x - 0.6) < 1e-9, n.x
    assert abs(n.y - 0.0) < 1e-9, n.y
    assert abs(n.z - 0.8) < 1e-9, n.z

    # Original vector unchanged by non-ip variant.
    assert abs(v.x - 3.0) < 1e-9 and abs(v.z - 4.0) < 1e-9, v

    print(case_id, "ok", n.length())
finally:
    pygame.quit()
PY
