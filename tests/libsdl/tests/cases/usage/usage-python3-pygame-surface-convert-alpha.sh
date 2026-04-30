#!/usr/bin/env bash
# @testcase: usage-python3-pygame-surface-convert-alpha
# @title: Pygame surface convert and convert_alpha
# @description: Creates a Pygame surface, hides the prompt, switches between convert and convert_alpha pixel formats, and verifies the alpha-converted surface reports per-pixel alpha bits.
# @timeout: 180
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-surface-convert-alpha"
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
    pygame.display.set_mode((1, 1))
    base = pygame.Surface((4, 4))
    plain = base.convert()
    alpha = base.convert_alpha()
    assert plain.get_size() == (4, 4)
    assert alpha.get_size() == (4, 4)
    assert alpha.get_bitsize() >= plain.get_bitsize()
    assert alpha.get_alpha() is not None or alpha.get_flags() & pygame.SRCALPHA
    print("convert", plain.get_bitsize(), "alpha", alpha.get_bitsize())
finally:
    pygame.quit()
PY
