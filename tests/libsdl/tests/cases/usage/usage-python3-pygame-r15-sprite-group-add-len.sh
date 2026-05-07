#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r15-sprite-group-add-len
# @title: Pygame sprite.Group reports len equal to the number of added sprites
# @description: Constructs three pygame.sprite.Sprite instances, adds them to a sprite.Group, and asserts len(group) is 3 and that each sprite is reported as alive after add.
# @timeout: 60
# @tags: usage, sdl, python, sprite
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
from pygame.sprite import Sprite, Group

pygame.init()
try:
    group = Group()
    sprites = [Sprite(), Sprite(), Sprite()]
    for s in sprites:
        group.add(s)
    assert len(group) == 3, len(group)
    for s in sprites:
        assert s.alive(), s
finally:
    pygame.quit()
PY
