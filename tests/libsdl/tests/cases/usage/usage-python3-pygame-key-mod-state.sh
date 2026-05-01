#!/usr/bin/env bash
# @testcase: usage-python3-pygame-key-mod-state
# @title: pygame.key modifier state and name lookup
# @description: After display init under the dummy driver, queries pygame.key.get_mods plus pygame.key.name and pygame.key.key_code for several constants to confirm modifier state is an integer with no modifiers held and that name/key_code form a round-trip for known keys.
# @timeout: 120
# @tags: usage, key
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy
export PYGAME_HIDE_SUPPORT_PROMPT=1

case_id="usage-python3-pygame-key-mod-state"

python3 - <<'PY' "$case_id"
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    pygame.display.init()
    pygame.display.set_mode((1, 1))
    mods = pygame.key.get_mods()
    assert isinstance(mods, int), type(mods)
    assert mods & pygame.KMOD_NONE == 0 or mods == 0
    # No physical modifiers should be reported under dummy driver
    assert not (mods & pygame.KMOD_SHIFT)
    assert not (mods & pygame.KMOD_CTRL)

    pairs = [
        (pygame.K_a, "a"),
        (pygame.K_SPACE, "space"),
        (pygame.K_RETURN, "return"),
        (pygame.K_ESCAPE, "escape"),
    ]
    for code, expected in pairs:
        name = pygame.key.name(code)
        assert name == expected, (code, name, expected)
        rt = pygame.key.key_code(name)
        assert rt == code, (name, rt, code)
    print("key-mods", mods)
finally:
    pygame.quit()
PY
