#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-set-alpha
# @title: pygame Surface set_alpha
# @description: Calls Surface.set_alpha on an SRCALPHA surface with a range of values, confirming Surface.get_alpha reports the most recently configured alpha after each call.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-set-alpha"
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
    surface = pygame.Surface((4, 4), flags=pygame.SRCALPHA)
    observed = []
    for value in (0, 64, 128, 200, 255):
        surface.set_alpha(value)
        got = surface.get_alpha()
        assert got == value, (value, got)
        observed.append(got)
    print("set_alpha", observed)
finally:
    pygame.quit()
PY
