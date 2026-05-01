#!/usr/bin/env bash
# @testcase: usage-python3-pygame-sprite-group-add-remove
# @title: Pygame sprite group add and remove
# @description: Adds three Pygame sprites to a Group, removes one, and verifies the membership and ordering returned by sprites().
# @timeout: 120
# @tags: usage, sprite, python
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-sprite-group-add-remove"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame
from pygame.sprite import Sprite, Group

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    def make(name):
        sprite = Sprite()
        sprite.image = pygame.Surface((4, 4))
        sprite.rect = sprite.image.get_rect()
        sprite.name = name
        return sprite

    a = make("a")
    b = make("b")
    c = make("c")
    group = Group()
    group.add(a, b, c)
    assert len(group) == 3
    assert a in group and b in group and c in group

    group.remove(b)
    assert len(group) == 2
    assert b not in group
    names = sorted(s.name for s in group.sprites())
    assert names == ["a", "c"]

    group.empty()
    assert len(group) == 0
    print("sprites", names)
finally:
    pygame.quit()
PY
