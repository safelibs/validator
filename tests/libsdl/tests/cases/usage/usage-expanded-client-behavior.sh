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
import sys
import pygame

case_id = sys.argv[1]
pygame.init()
try:
    if case_id == 'usage-python3-pygame-surface-fill-rect':
        surface = pygame.Surface((4, 3))
        filled = surface.fill((12, 34, 56), pygame.Rect(1, 1, 2, 1))
        assert filled.topleft == (1, 1) and filled.size == (2, 1)
        assert surface.get_at((1, 1))[:3] == (12, 34, 56)
        print(filled)
    elif case_id == 'usage-python3-pygame-transform-average-color':
        surface = pygame.Surface((3, 2))
        surface.fill((40, 80, 120))
        assert pygame.transform.average_color(surface)[:3] == (40, 80, 120)
        print(pygame.transform.average_color(surface)[:3])
    elif case_id == 'usage-python3-pygame-transform-rotozoom':
        surface = pygame.Surface((3, 2))
        out = pygame.transform.rotozoom(surface, 0, 2.0)
        assert out.get_size() == (6, 4)
        print(out.get_size())
    elif case_id == 'usage-python3-pygame-rect-move-ip':
        rect = pygame.Rect(5, 4, 3, 2)
        rect.move_ip(-2, 3)
        assert rect.topleft == (3, 7)
        print(rect.topleft)
    elif case_id == 'usage-python3-pygame-vector2-dot-product':
        value = pygame.math.Vector2(2, 3).dot(pygame.math.Vector2(-1, 4))
        assert value == 10
        print(value)
    elif case_id == 'usage-python3-pygame-mask-centroid':
        mask = pygame.mask.Mask((5, 4), fill=False)
        mask.set_at((2, 1), 1)
        assert mask.centroid() == (2, 1)
        print(mask.centroid())
    elif case_id == 'usage-python3-pygame-font-linesize':
        font = pygame.font.Font(None, 24)
        assert font.get_linesize() >= font.get_height() > 0
        print(font.get_linesize())
    elif case_id == 'usage-python3-pygame-event-name-keydown':
        name = pygame.event.event_name(pygame.KEYDOWN)
        assert name.lower().startswith('key')
        print(name)
    elif case_id == 'usage-python3-pygame-display-get-driver':
        pygame.display.set_mode((4, 4))
        assert pygame.display.get_driver() == 'dummy'
        print(pygame.display.get_driver())
    elif case_id == 'usage-python3-pygame-surface-clip-fill':
        surface = pygame.Surface((2, 2), pygame.SRCALPHA)
        surface.fill((255, 0, 0, 255))
        surface.set_clip(pygame.Rect(1, 0, 1, 2))
        surface.fill((0, 255, 0, 255))
        assert surface.get_clip() == pygame.Rect(1, 0, 1, 2)
        assert surface.get_at((1, 0))[:3] == (0, 255, 0)
        assert surface.get_at((0, 0))[:3] == (255, 0, 0)
        print(surface.get_clip())
    else:
        raise SystemExit(f'unknown libsdl expanded usage case: {case_id}')
finally:
    pygame.quit()
PYCASE
