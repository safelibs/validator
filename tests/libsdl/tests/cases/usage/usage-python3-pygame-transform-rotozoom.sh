#!/usr/bin/env bash
# @testcase: usage-python3-pygame-transform-rotozoom
# @title: pygame transform rotozoom
# @description: Applies pygame.transform.rotozoom with a scale factor of two and verifies the resulting surface dimensions double exactly.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-transform-rotozoom"
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
    surface = pygame.Surface((3, 2))
    out = pygame.transform.rotozoom(surface, 0, 2.0)
    assert out.get_size() == (6, 4)
    print(out.get_size())
finally:
    pygame.quit()
PYCASE
