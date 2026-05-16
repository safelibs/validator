#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-key-name-roundtrip-via-key-code
# @title: Pygame key.key_code('a') matches pygame.K_a and round-trips through key.name
# @description: Calls pygame.key.key_code('a') and asserts it equals pygame.K_a, then calls pygame.key.name on that constant and asserts the returned name is "a", pinning the SDL keysym name<->code translation symmetry.
# @timeout: 60
# @tags: usage, sdl, python, key, keycode, r21
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
pygame.init()
try:
    code = pygame.key.key_code('a')
    assert code == pygame.K_a, (code, pygame.K_a)
    name = pygame.key.name(code)
    assert name == 'a', name
finally:
    pygame.quit()
PY
