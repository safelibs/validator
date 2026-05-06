#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r10-sprite-layered-updates
# @title: Pygame LayeredUpdates respects per-sprite z-order
# @description: Adds three sprites to a LayeredUpdates group with explicit layers and verifies sprites() returns them in ascending layer order.
# @timeout: 120
# @tags: usage, sdl, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
from pygame.sprite import Sprite, LayeredUpdates

pygame.init()
try:
    def make_sprite(tag):
        s = Sprite()
        s.image = pygame.Surface((4, 4))
        s.rect = s.image.get_rect()
        s.tag = tag
        return s

    bottom = make_sprite("bottom")
    middle = make_sprite("middle")
    top = make_sprite("top")

    group = LayeredUpdates()
    group.add(top, layer=10)
    group.add(bottom, layer=1)
    group.add(middle, layer=5)

    ordered = [s.tag for s in group.sprites()]
    assert ordered == ["bottom", "middle", "top"], ordered

    assert group.get_layer_of_sprite(top) == 10
    assert group.layers() == [1, 5, 10]
finally:
    pygame.quit()
PY
