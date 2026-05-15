#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r19-sprite-group-add-and-len
# @title: Pygame sprite.Group reports len equal to the number of added sprites
# @description: Creates three pygame.sprite.Sprite instances with image+rect, adds them to a Group, and asserts len(group) is 3 and all sprites appear in the group's sprites() list, pinning the sprite-group membership API.
# @timeout: 60
# @tags: usage, sdl, python, sprite, group, r19
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
    g = pygame.sprite.Group()
    sprites = []
    for i in range(3):
        sp = pygame.sprite.Sprite()
        sp.image = pygame.Surface((4, 4))
        sp.rect = sp.image.get_rect(topleft=(i, i))
        sprites.append(sp)
        g.add(sp)
    assert len(g) == 3, len(g)
    listed = g.sprites()
    assert len(listed) == 3, len(listed)
    for sp in sprites:
        assert sp in listed
finally:
    pygame.quit()
PY
