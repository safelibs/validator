#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    if case_id == 'usage-python3-pygame-rect-clamp':
        inner = pygame.Rect(8, 8, 4, 4)
        outer = pygame.Rect(0, 0, 10, 10)
        clamped = inner.clamp(outer)
        assert outer.contains(clamped)
        print(clamped.topleft)
    elif case_id == 'usage-python3-pygame-subsurface-size':
        surface = pygame.Surface((8, 6))
        sub = surface.subsurface(pygame.Rect(2, 1, 3, 2))
        assert sub.get_size() == (3, 2)
        print(sub.get_size())
    elif case_id == 'usage-python3-pygame-vector2-length':
        value = pygame.math.Vector2(3, 4)
        assert math.isclose(value.length(), 5.0)
        print(value.length())
    elif case_id == 'usage-python3-pygame-draw-arc':
        surface = pygame.Surface((12, 12))
        surface.fill((0, 0, 0))
        pygame.draw.arc(surface, (255, 0, 0), pygame.Rect(1, 1, 10, 10), 0, math.pi, 1)
        painted = sum(
            1
            for y in range(surface.get_height())
            for x in range(surface.get_width())
            if surface.get_at((x, y))[:3] != (0, 0, 0)
        )
        assert painted > 0
        print(painted)
    elif case_id == 'usage-python3-pygame-surface-colorkey':
        surface = pygame.Surface((4, 4))
        surface.set_colorkey((1, 2, 3))
        assert surface.get_colorkey()[:3] == (1, 2, 3)
        print(surface.get_colorkey())
    elif case_id == 'usage-python3-pygame-display-caption':
        pygame.display.set_mode((4, 4))
        pygame.display.set_caption('validator-caption')
        assert pygame.display.get_caption()[0] == 'validator-caption'
        print(pygame.display.get_caption()[0])
    elif case_id == 'usage-python3-pygame-time-wait':
        before = pygame.time.get_ticks()
        pygame.time.wait(5)
        after = pygame.time.get_ticks()
        assert after >= before
        print(after - before)
    elif case_id == 'usage-python3-pygame-transform-scale2x':
        surface = pygame.Surface((3, 2))
        out = pygame.transform.scale2x(surface)
        assert out.get_size() == (6, 4)
        print(out.get_size())
    elif case_id == 'usage-python3-pygame-mask-from-threshold':
        surface = pygame.Surface((4, 4))
        surface.fill((0, 0, 0))
        surface.set_at((1, 1), (255, 0, 0))
        mask = pygame.mask.from_threshold(surface, (255, 0, 0), (1, 1, 1, 255))
        assert mask.count() == 1
        print(mask.count())
    elif case_id == 'usage-python3-pygame-event-set-blocked':
        pygame.event.set_blocked(pygame.MOUSEMOTION)
        assert pygame.event.get_blocked(pygame.MOUSEMOTION)
        print('blocked')
    else:
        raise SystemExit(f'unknown libsdl even-more usage case: {case_id}')
finally:
    pygame.quit()
PY
