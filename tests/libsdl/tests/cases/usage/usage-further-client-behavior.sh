#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PYCASE' "$case_id"
import math
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    if case_id == 'usage-python3-pygame-rect-fit':
        inner = pygame.Rect(0, 0, 20, 10)
        outer = pygame.Rect(0, 0, 5, 5)
        fitted = inner.fit(outer)
        assert fitted.width == 5 and fitted.height == 2
        print(fitted.size)
    elif case_id == 'usage-python3-pygame-rect-normalize':
        rect = pygame.Rect(5, 5, -3, -2)
        rect.normalize()
        assert rect.topleft == (2, 3) and rect.size == (3, 2)
        print(rect)
    elif case_id == 'usage-python3-pygame-vector2-rotate':
        value = pygame.math.Vector2(1, 0).rotate(90)
        assert math.isclose(value.x, 0.0, abs_tol=1e-6)
        assert math.isclose(value.y, 1.0, abs_tol=1e-6)
        print(round(value.y, 1))
    elif case_id == 'usage-python3-pygame-draw-aaline':
        surface = pygame.Surface((12, 12))
        surface.fill((0, 0, 0))
        pygame.draw.aaline(surface, (255, 255, 255), (1, 1), (10, 8))
        painted = sum(
            1
            for y in range(surface.get_height())
            for x in range(surface.get_width())
            if surface.get_at((x, y))[:3] != (0, 0, 0)
        )
        assert painted > 0
        print(painted)
    elif case_id == 'usage-python3-pygame-mask-outline':
        mask = pygame.mask.Mask((4, 4), fill=False)
        mask.set_at((1, 1), 1)
        mask.set_at((2, 1), 1)
        mask.set_at((1, 2), 1)
        mask.set_at((2, 2), 1)
        outline = mask.outline()
        assert len(outline) >= 4
        print(len(outline))
    elif case_id == 'usage-python3-pygame-event-clear':
        event_type = pygame.USEREVENT + 1
        pygame.event.post(pygame.event.Event(event_type, value=7))
        pygame.event.clear(event_type)
        assert not pygame.event.get(event_type)
        print('cleared')
    elif case_id == 'usage-python3-pygame-surface-map-rgb':
        surface = pygame.Surface((2, 2))
        mapped = surface.map_rgb((12, 34, 56))
        color = surface.unmap_rgb(mapped)
        assert color[:3] == (12, 34, 56)
        print(color[:3])
    elif case_id == 'usage-python3-pygame-surface-bounding-rect':
        surface = pygame.Surface((4, 4), pygame.SRCALPHA)
        surface.fill((0, 0, 0, 0))
        surface.set_at((2, 1), (255, 0, 0, 255))
        rect = surface.get_bounding_rect()
        assert rect.topleft == (2, 1) and rect.size == (1, 1)
        print(rect)
    elif case_id == 'usage-python3-pygame-font-size':
        font = pygame.font.Font(None, 24)
        width, height = font.size('validator')
        assert width > 0 and height > 0
        print(width, height)
    elif case_id == 'usage-python3-pygame-color-hsva':
        color = pygame.Color(0, 0, 0)
        color.hsva = (120, 100, 100, 100)
        assert color.g == 255 and color.r == 0 and color.b == 0
        print(color.g)
    else:
        raise SystemExit(f'unknown libsdl further usage case: {case_id}')
finally:
    pygame.quit()
PYCASE
