#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r12-sprite-group-len
# @title: Pygame sprite.Group len reflects added and removed sprites
# @description: Creates a Group, adds three Sprite instances, removes one, and asserts len(group) tracks the membership transitions correctly.
# @timeout: 120
# @tags: usage, sdl, python, sprite
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
    group = pygame.sprite.Group()
    sprites = [pygame.sprite.Sprite() for _ in range(3)]
    for s in sprites:
        s.image = pygame.Surface((2, 2))
        s.rect = s.image.get_rect()
    group.add(*sprites)
    assert len(group) == 3, len(group)
    group.remove(sprites[1])
    assert len(group) == 2, len(group)
    assert sprites[0] in group
    assert sprites[1] not in group
    assert sprites[2] in group
finally:
    pygame.quit()
PY
