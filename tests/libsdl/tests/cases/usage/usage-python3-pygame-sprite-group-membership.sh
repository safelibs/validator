#!/usr/bin/env bash
# @testcase: usage-python3-pygame-sprite-group-membership
# @title: Pygame sprite group membership
# @description: Builds a pygame.sprite.Group, exercises add/remove/has, and verifies sprite count and iteration order before and after removal.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-sprite-group-membership"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    def make(idx):
        sp = pygame.sprite.Sprite()
        sp.image = pygame.Surface((4, 4))
        sp.rect = sp.image.get_rect()
        sp.rect.topleft = (idx * 5, 0)
        sp.idx = idx
        return sp

    sprites = [make(i) for i in range(4)]
    group = pygame.sprite.Group()
    group.add(*sprites)
    assert len(group) == 4
    for s in sprites:
        assert group.has(s)
    group.remove(sprites[1], sprites[2])
    assert len(group) == 2
    assert not group.has(sprites[1])
    assert not group.has(sprites[2])
    remaining = sorted(s.idx for s in group)
    assert remaining == [0, 3], remaining
    group.empty()
    assert len(group) == 0
    print("group", remaining)
finally:
    pygame.quit()
PY
