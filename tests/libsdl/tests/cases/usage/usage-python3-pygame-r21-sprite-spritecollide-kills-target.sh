#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-sprite-spritecollide-kills-target
# @title: Pygame sprite.spritecollide(dokill=True) removes the colliding sprite from the group
# @description: Builds a probe Sprite and a Group with two sprites (one overlapping), calls spritecollide(probe, group, dokill=True), asserts the returned list length is exactly 1, and verifies the group's remaining size is 1 after the kill, pinning the SDL-backed sprite collision-and-remove semantics.
# @timeout: 60
# @tags: usage, sdl, python, sprite, spritecollide, r21
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
    class S(pygame.sprite.Sprite):
        def __init__(self, rect):
            super().__init__()
            self.image = pygame.Surface((rect.w, rect.h))
            self.rect = rect

    probe = S(pygame.Rect(0, 0, 10, 10))
    a = S(pygame.Rect(5, 5, 10, 10))      # overlaps probe
    b = S(pygame.Rect(100, 100, 10, 10))  # does not overlap

    group = pygame.sprite.Group(a, b)
    hits = pygame.sprite.spritecollide(probe, group, dokill=True)
    assert len(hits) == 1, len(hits)
    assert hits[0] is a, hits
    assert len(group) == 1, len(group)
finally:
    pygame.quit()
PY
