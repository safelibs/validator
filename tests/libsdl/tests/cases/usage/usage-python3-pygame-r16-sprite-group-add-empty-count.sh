#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r16-sprite-group-add-empty-count
# @title: Pygame sprite.Group add then empty zeroes the membership count
# @description: Creates three Sprite instances, adds them to a Group, asserts len(group) == 3, then calls group.empty() and asserts len(group) == 0 — pinning the empty()-clears-membership contract.
# @timeout: 120
# @tags: usage, sdl, python, sprite, group
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
import pygame.sprite

pygame.init()
try:
    group = pygame.sprite.Group()
    sprites = [pygame.sprite.Sprite() for _ in range(3)]
    for s in sprites:
        s.image = pygame.Surface((2, 2))
        s.rect = s.image.get_rect()
        group.add(s)
    assert len(group) == 3, len(group)
    group.empty()
    assert len(group) == 0, len(group)
finally:
    pygame.quit()
PY
