#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-rect-collidedict-returns-pair
# @title: Pygame Rect.collidedict returns the (key, value) pair of the first colliding rect
# @description: Builds a probe Rect plus a dict whose keys are rect-style tuples and values are integer labels, calls collidedict with values=False, and asserts the returned tuple's key tuple identifies the overlapping rect, pinning the dict-traversal collision lookup behavior of the SDL-backed Rect helper.
# @timeout: 60
# @tags: usage, sdl, python, rect, collidedict, r21
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
    probe = pygame.Rect(20, 20, 5, 5)
    # collidedict requires rect-style keys (4-tuples)
    candidates = {
        (200, 200, 5, 5): 'far',
        (22, 22, 5, 5): 'hit',
        (300, 300, 5, 5): 'distant',
    }
    res = probe.collidedict(candidates)
    assert res is not None
    key, val = res
    assert key == (22, 22, 5, 5), key
    assert val == 'hit', val
finally:
    pygame.quit()
PY
