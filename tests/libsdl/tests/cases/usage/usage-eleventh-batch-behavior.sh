#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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
    if case_id == 'usage-python3-pygame-color-hsla-batch11':
        color = pygame.Color(255, 0, 0)
        h, s, l, a = color.hsla
        assert int(h) == 0 and int(s) == 100 and int(l) == 50 and int(a) == 100
        print('hsla', color.hsla)
    elif case_id == 'usage-python3-pygame-surface-lock-state-batch11':
        surface = pygame.Surface((2, 2))
        assert not surface.get_locked()
        surface.lock()
        assert surface.get_locked()
        surface.unlock()
        assert not surface.get_locked()
        print('lock-state')
    elif case_id == 'usage-python3-pygame-transform-flip-batch11':
        surface = pygame.Surface((2, 1))
        surface.set_at((0, 0), (10, 20, 30))
        surface.set_at((1, 0), (90, 80, 70))
        out = pygame.transform.flip(surface, True, False)
        assert out.get_at((0, 0))[:3] == (90, 80, 70)
        print('flip')
    elif case_id == 'usage-python3-pygame-draw-circle-batch11':
        surface = pygame.Surface((7, 7))
        rect = pygame.draw.circle(surface, (200, 10, 20), (3, 3), 2)
        assert rect.width >= 4 and rect.height >= 4
        assert surface.get_at((3, 3))[:3] == (200, 10, 20)
        print('circle', rect)
    elif case_id == 'usage-python3-pygame-event-custom-type-batch11':
        event_type = pygame.event.custom_type()
        pygame.event.post(pygame.event.Event(event_type, payload='ok'))
        events = pygame.event.get(event_type)
        assert len(events) == 1 and events[0].payload == 'ok'
        print('event', event_type)
    elif case_id == 'usage-python3-pygame-time-busy-loop-batch11':
        clock = pygame.time.Clock()
        elapsed = clock.tick_busy_loop(120)
        assert elapsed >= 0
        print('busy', elapsed)
    elif case_id == 'usage-python3-pygame-font-render-size-batch11':
        pygame.font.init()
        font = pygame.font.Font(None, 18)
        rendered = font.render('SDL', True, (255, 255, 255))
        assert rendered.get_width() > 0 and rendered.get_height() > 0
        print('font', rendered.get_size())
    elif case_id == 'usage-python3-pygame-sprite-collide-rect-batch11':
        a = pygame.sprite.Sprite(); a.rect = pygame.Rect(0, 0, 10, 10)
        b = pygame.sprite.Sprite(); b.rect = pygame.Rect(5, 5, 3, 3)
        assert pygame.sprite.collide_rect(a, b)
        print('collide')
    elif case_id == 'usage-python3-pygame-mask-connected-components-batch11':
        mask = pygame.mask.Mask((4, 4), fill=False)
        mask.set_at((1, 1), 1)
        mask.set_at((3, 3), 1)
        components = mask.connected_components()
        assert len(components) == 2
        assert sorted(component.count() for component in components) == [1, 1]
        print('mask-components')
    elif case_id == 'usage-python3-pygame-image-roundtrip-png-batch11':
        path = os.path.join(tmpdir, 'roundtrip.png')
        surface = pygame.Surface((3, 3))
        surface.fill((30, 60, 90))
        pygame.image.save(surface, path)
        loaded = pygame.image.load(path)
        assert loaded.get_size() == (3, 3)
        assert loaded.get_at((0, 0))[:3] == (30, 60, 90)
        print('png')
    else:
        raise SystemExit(f'unknown libsdl eleventh-batch usage case: {case_id}')
finally:
    pygame.quit()
PYCASE
