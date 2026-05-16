#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-vector2-project-onto-known-axis
# @title: Pygame Vector2.project onto x-axis returns the x-only component vector
# @description: Constructs pygame.math.Vector2(3, 4) and projects it onto Vector2(1, 0), asserting the result is approximately (3.0, 0.0), pinning the vector projection helper provided by pygame's SDL-backed math module.
# @timeout: 60
# @tags: usage, sdl, python, vector2, project, r21
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
    v = pygame.math.Vector2(3, 4)
    axis = pygame.math.Vector2(1, 0)
    p = v.project(axis)
    assert abs(p.x - 3.0) < 1e-9, p
    assert abs(p.y - 0.0) < 1e-9, p
finally:
    pygame.quit()
PY
