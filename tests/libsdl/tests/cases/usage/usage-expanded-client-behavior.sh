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
    if case_id == 'usage-python3-pygame-surface-alpha':
        surface = pygame.Surface((2, 2), pygame.SRCALPHA)
        surface.set_alpha(123)
        assert surface.get_alpha() == 123
        print(surface.get_alpha())
    elif case_id == 'usage-python3-pygame-transform-flip-horizontal':
        surface = pygame.Surface((2, 1))
        surface.set_at((0, 0), (255, 0, 0))
        surface.set_at((1, 0), (0, 0, 255))
        flipped = pygame.transform.flip(surface, True, False)
        assert flipped.get_at((0, 0))[:3] == (0, 0, 255)
        print(flipped.get_at((0, 0))[:3])
    elif case_id == 'usage-python3-pygame-transform-flip-vertical':
        surface = pygame.Surface((1, 2))
        surface.set_at((0, 0), (255, 0, 0))
        surface.set_at((0, 1), (0, 255, 0))
        flipped = pygame.transform.flip(surface, False, True)
        assert flipped.get_at((0, 0))[:3] == (0, 255, 0)
        print(flipped.get_at((0, 0))[:3])
    elif case_id == 'usage-python3-pygame-draw-circle-center':
        surface = pygame.Surface((12, 12))
        surface.fill((0, 0, 0))
        pygame.draw.circle(surface, (255, 255, 255), (6, 6), 3)
        assert surface.get_at((6, 6))[:3] == (255, 255, 255)
        print(surface.get_at((6, 6))[:3])
    elif case_id == 'usage-python3-pygame-clock-tick-delta':
        clock = pygame.time.Clock()
        delta = clock.tick(60)
        assert isinstance(delta, int) and delta >= 0
        print(delta)
    elif case_id == 'usage-python3-pygame-rect-clamp-inside':
        rect = pygame.Rect(10, 10, 5, 5)
        area = pygame.Rect(0, 0, 8, 8)
        clamped = rect.clamp(area)
        assert clamped.right <= area.right and clamped.bottom <= area.bottom
        print(clamped.topleft)
    elif case_id == 'usage-python3-pygame-vector2-length-value':
        value = pygame.math.Vector2(3, 4)
        assert math.isclose(value.length(), 5.0, abs_tol=1e-6)
        print(value.length())
    elif case_id == 'usage-python3-pygame-mask-count-opaque':
        surface = pygame.Surface((3, 3), pygame.SRCALPHA)
        surface.fill((0, 0, 0, 0))
        surface.set_at((1, 1), (255, 255, 255, 255))
        mask = pygame.mask.from_surface(surface)
        assert mask.count() == 1
        print(mask.count())
    elif case_id == 'usage-python3-pygame-font-render-size':
        font = pygame.font.Font(None, 24)
        rendered = font.render('validator', True, (255, 255, 255))
        assert rendered.get_width() > 0 and rendered.get_height() > 0
        print(rendered.get_size())
    elif case_id == 'usage-python3-pygame-event-post-custom':
        event_type = pygame.USEREVENT + 2
        pygame.event.post(pygame.event.Event(event_type, payload='ok'))
        events = pygame.event.get(event_type)
        assert len(events) == 1 and events[0].payload == 'ok'
        print(events[0].payload)
    else:
        raise SystemExit(f'unknown libsdl expanded usage case: {case_id}')
finally:
    pygame.quit()
PYCASE
