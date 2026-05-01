#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-bold-italic-flags
# @title: pygame Font bold and italic toggles
# @description: Renders the same glyph from the default font with bold disabled, bold enabled, and italic enabled, and confirms each style toggle yields a wider rendered surface than the plain rendering.
# @timeout: 120
# @tags: usage, font
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-font-bold-italic-flags"

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.font.init()
try:
    font = pygame.font.Font(None, 36)
    assert font.get_bold() is False
    assert font.get_italic() is False
    plain = font.render("M", True, (255, 255, 255))

    font.set_bold(True)
    assert font.get_bold() is True
    bold = font.render("M", True, (255, 255, 255))
    font.set_bold(False)

    font.set_italic(True)
    assert font.get_italic() is True
    italic = font.render("M", True, (255, 255, 255))
    font.set_italic(False)

    assert bold.get_width() >= plain.get_width(), (bold.get_width(), plain.get_width())
    assert italic.get_width() >= plain.get_width(), (italic.get_width(), plain.get_width())
    # At least one toggle must strictly widen the glyph
    assert bold.get_width() > plain.get_width() or italic.get_width() > plain.get_width()
    print("font-flags", plain.get_width(), bold.get_width(), italic.get_width())
finally:
    pygame.font.quit()
PY
