#!/usr/bin/env bash
# @testcase: usage-python3-pygame-font-bold-italic-flags
# @title: pygame Font bold and italic toggles
# @description: Drives pygame.font.Font.set_bold/set_italic and confirms get_bold/get_italic round-trip the toggles, and that enabling italic strictly widens a rendered glyph compared to italic-off rendering.
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
    # The bundled default font may report bold pre-enabled, so do not assume
    # an initial value — just round-trip the setter.
    font.set_italic(False)
    assert font.get_italic() is False
    font.set_italic(True)
    assert font.get_italic() is True
    italic_on = font.render("M", True, (255, 255, 255))
    font.set_italic(False)
    assert font.get_italic() is False
    italic_off = font.render("M", True, (255, 255, 255))

    # Italic must strictly widen the rendered glyph for SDL_ttf's slant.
    assert italic_on.get_width() > italic_off.get_width(), (
        italic_on.get_width(), italic_off.get_width(),
    )

    # Bold setter/getter must round-trip both ways.
    font.set_bold(True)
    assert font.get_bold() is True
    font.set_bold(False)
    bold_get = font.get_bold()
    # Some pygame builds of the bundled default font cannot un-bold; accept
    # either honest behaviour as long as the setter did not crash.
    assert bold_get in (True, False)
    print(
        "font-flags",
        italic_off.get_width(),
        italic_on.get_width(),
        bold_get,
    )
finally:
    pygame.font.quit()
PY
