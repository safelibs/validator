#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-sysfont
# @title: Pygame font SysFont fallback
# @description: Calls pygame.font.SysFont with a likely-missing family name and verifies pygame falls back to a usable Font object that can still render text.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-font-sysfont"
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
pygame.font.init()
try:
    # SysFont always returns a Font object even when the family is unknown,
    # falling back to the default font.
    font = pygame.font.SysFont("definitely-not-a-real-family-xyz", 18)
    assert isinstance(font, pygame.font.Font), type(font)

    # The fallback must still be capable of rendering.
    surface = font.render("ok", True, (255, 255, 255))
    width, height = surface.get_size()
    assert width > 0 and height > 0, (width, height)

    # match_font may legitimately return None for an unknown family.
    match = pygame.font.match_font("definitely-not-a-real-family-xyz")
    assert match is None or isinstance(match, str), match

    print(case_id, "ok", width, height, match)
finally:
    pygame.font.quit()
    pygame.quit()
PY
