#!/usr/bin/env bash
# @testcase: usage-python3-pygame-sprite-collide-rect-batch11
# @title: pygame sprite collide rect
# @description: Checks rectangle collision between two pygame Sprite instances.
# @timeout: 180
# @tags: usage, pygame, sdl
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-sprite-collide-rect-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    a = pygame.sprite.Sprite(); a.rect = pygame.Rect(0, 0, 10, 10)
    b = pygame.sprite.Sprite(); b.rect = pygame.Rect(5, 5, 3, 3)
    assert pygame.sprite.collide_rect(a, b)
    print('collide')
finally:
    pygame.quit()
PYCASE
