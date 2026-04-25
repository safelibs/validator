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
    elif case_id == "usage-python3-pygame-draw-circle":
        surface = pygame.Surface((10, 10))
        pygame.draw.circle(surface, (0, 255, 0), (5, 5), 3)
        assert surface.get_at((5, 2)).g == 255
        print("circle", surface.get_at((5, 2)))
    elif case_id == "usage-python3-pygame-transform-flip":
        surface = pygame.Surface((6, 4))
        flipped = pygame.transform.flip(surface, True, False)
        assert flipped.get_size() == (6, 4)
        print("flip", flipped.get_size())
    elif case_id == "usage-python3-pygame-surface-copy":
        surface = pygame.Surface((4, 4))
        surface.fill((20, 30, 40))
        copied = surface.copy()
        assert copied.get_at((0, 0)) == surface.get_at((0, 0))
        print("copy", copied.get_at((0, 0)))
    elif case_id == "usage-python3-pygame-color-lerp":
        color = pygame.Color(0, 0, 0).lerp((255, 0, 0), 0.5)
        assert color.r > 0
        print("color", color.r)
    elif case_id == "usage-python3-pygame-pixelarray":
        surface = pygame.Surface((4, 4))
        pixels = pygame.PixelArray(surface)
        pixels[1][1] = surface.map_rgb((255, 0, 0))
        del pixels
        assert surface.get_at((1, 1)).r == 255
        print("pixel", surface.get_at((1, 1)))
    elif case_id == "usage-python3-pygame-custom-event":
        event_type = pygame.USEREVENT + 1
        pygame.event.clear()
        pygame.event.post(pygame.event.Event(event_type, value="ok"))
        event = pygame.event.poll()
        assert event.type == event_type and event.value == "ok"
        print("event", event.value)
    elif case_id == "usage-python3-pygame-font-render":
        pygame.font.init()
        font = pygame.font.Font(None, 24)
        surface = font.render("hello", True, (255, 255, 255))
        assert surface.get_width() > 0 and surface.get_height() > 0
        print("font", surface.get_size())
    elif case_id == "usage-python3-pygame-mask-overlap-area":
        first = pygame.mask.Mask((4, 4), fill=True)
        second = pygame.mask.Mask((4, 4), fill=True)
        area = first.overlap_area(second, (1, 1))
        assert area > 0
        print("area", area)
    elif case_id == "usage-python3-pygame-image-tostring":
        surface = pygame.Surface((4, 4))
        data = pygame.image.tostring(surface, "RGB")
        assert len(data) == 4 * 4 * 3
        print("bytes", len(data))
    elif case_id == "usage-python3-pygame-rect-union":
        first = pygame.Rect(0, 0, 2, 2)
        second = pygame.Rect(2, 1, 3, 2)
        union = first.union(second)
        assert union.size == (5, 3)
        print("union", union.size)
    else:
        raise SystemExit(f"unknown libsdl extra usage case: {case_id}")
finally:
    pygame.quit()
PY
