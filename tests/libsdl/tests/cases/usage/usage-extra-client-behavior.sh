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
import os
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    if case_id == "usage-python3-pygame-rect-collision":
        a = pygame.Rect(0, 0, 10, 10)
        b = pygame.Rect(5, 5, 3, 3)
        assert a.colliderect(b)
        print("collision", a.clip(b).size)
    elif case_id == "usage-python3-pygame-clock-tick":
        clock = pygame.time.Clock()
        delta = clock.tick(60)
        assert delta >= 0
        print("tick", delta)
    elif case_id == "usage-python3-pygame-transform-rotate":
        surface = pygame.Surface((6, 4))
        rotated = pygame.transform.rotate(surface, 90)
        assert rotated.get_size() == (4, 6)
        print("rotate", rotated.get_size())
    elif case_id == "usage-python3-pygame-draw-line":
        surface = pygame.Surface((8, 8))
        pygame.draw.line(surface, (255, 0, 0), (0, 0), (7, 7), 1)
        assert surface.get_at((3, 3)).r == 255
        print("line", surface.get_at((3, 3)))
    elif case_id == "usage-python3-pygame-image-load":
        path = os.path.join(tmpdir, "image.bmp")
        surface = pygame.Surface((5, 4))
        surface.fill((0, 128, 255))
        pygame.image.save(surface, path)
        loaded = pygame.image.load(path)
        assert loaded.get_size() == (5, 4)
        print("load", loaded.get_size())
    elif case_id == "usage-python3-pygame-surfarray":
        surface = pygame.Surface((4, 3))
        array = pygame.surfarray.array3d(surface)
        assert array.shape[:2] == (4, 3)
        print("array", array.shape)
    elif case_id == "usage-python3-pygame-mouse-event":
        pygame.event.clear()
        pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(2, 3)))
        event = pygame.event.poll()
        assert event.type == pygame.MOUSEBUTTONDOWN and event.pos == (2, 3)
        print("mouse", event.pos)
    elif case_id == "usage-python3-pygame-time-delay":
        before = pygame.time.get_ticks()
        pygame.time.delay(5)
        after = pygame.time.get_ticks()
        assert after >= before
        print("delay", after - before)
    elif case_id == "usage-python3-pygame-font-metrics":
        pygame.font.init()
        font = pygame.font.Font(None, 18)
        metrics = font.metrics("abc")
        assert len(metrics) == 3 and all(item is not None for item in metrics)
        print("metrics", len(metrics))
    elif case_id == "usage-python3-pygame-alpha-blit":
        base = pygame.Surface((4, 4), pygame.SRCALPHA)
        overlay = pygame.Surface((4, 4), pygame.SRCALPHA)
        overlay.fill((255, 0, 0, 128))
        base.blit(overlay, (0, 0))
        assert base.get_at((1, 1)).a == 128
        print("alpha", base.get_at((1, 1)).a)
    else:
        raise SystemExit(f"unknown libsdl extra usage case: {case_id}")
finally:
    pygame.quit()
PY
