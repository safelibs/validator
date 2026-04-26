#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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
    if case_id == "usage-python3-pygame-draw-ellipse":
        surface = pygame.Surface((12, 10))
        pygame.draw.ellipse(surface, (255, 0, 0), pygame.Rect(1, 1, 10, 8))
        assert surface.get_at((6, 1)).r == 255
        print("ellipse", surface.get_at((6, 1)))
    elif case_id == "usage-python3-pygame-draw-polygon":
        surface = pygame.Surface((12, 12))
        pygame.draw.polygon(surface, (0, 255, 0), [(1, 10), (6, 1), (10, 10)])
        assert surface.get_at((6, 5)).g == 255
        print("polygon", surface.get_at((6, 5)))
    elif case_id == "usage-python3-pygame-transform-smoothscale":
        surface = pygame.Surface((8, 6))
        scaled = pygame.transform.smoothscale(surface, (4, 3))
        assert scaled.get_size() == (4, 3)
        print("smoothscale", scaled.get_size())
    elif case_id == "usage-python3-pygame-rect-clip":
        first = pygame.Rect(0, 0, 6, 6)
        second = pygame.Rect(3, 2, 6, 6)
        clipped = first.clip(second)
        assert clipped.size == (3, 4)
        print("clip", clipped.size)
    elif case_id == "usage-python3-pygame-surface-scroll":
        surface = pygame.Surface((6, 4))
        surface.fill((0, 0, 0))
        surface.set_at((1, 1), (255, 0, 0))
        surface.scroll(dx=2, dy=1)
        assert surface.get_at((3, 2)).r == 255
        print("scroll", surface.get_at((3, 2)))
    elif case_id == "usage-python3-pygame-timer-event":
        event_type = pygame.USEREVENT + 3
        pygame.event.clear()
        pygame.time.set_timer(event_type, 5, loops=1)
        event = pygame.event.wait()
        assert event.type == event_type
        print("timer", event.type)
    elif case_id == "usage-python3-pygame-event-peek":
        event_type = pygame.USEREVENT + 4
        pygame.event.clear()
        pygame.event.post(pygame.event.Event(event_type, value=7))
        assert pygame.event.peek(event_type)
        event = pygame.event.poll()
        assert event.type == event_type and event.value == 7
        print("peek", event.value)
    elif case_id == "usage-python3-pygame-image-fromstring":
        data = bytes([
            255, 0, 0, 0, 255, 0,
            0, 0, 255, 255, 255, 0,
        ])
        surface = pygame.image.fromstring(data, (2, 2), "RGB")
        assert surface.get_size() == (2, 2)
        assert surface.get_at((1, 1)).r == 255
        print("fromstring", surface.get_size())
    elif case_id == "usage-python3-pygame-mask-count":
        surface = pygame.Surface((6, 6), pygame.SRCALPHA)
        pygame.draw.rect(surface, (255, 255, 255, 255), pygame.Rect(1, 1, 3, 2))
        mask = pygame.mask.from_surface(surface)
        assert mask.count() == 6
        print("mask", mask.count())
    elif case_id == "usage-python3-pygame-display-set-mode":
        screen = pygame.display.set_mode((8, 6))
        assert screen.get_size() == (8, 6)
        print("display", screen.get_size())
    else:
        raise SystemExit(f"unknown libsdl additional usage case: {case_id}")
finally:
    pygame.quit()
PY
