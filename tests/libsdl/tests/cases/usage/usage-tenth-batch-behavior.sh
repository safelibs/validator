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
import os
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]
pygame.init()
try:
    if case_id == "usage-python3-pygame-rect-inflate-ip":
        rect = pygame.Rect(2, 3, 4, 6)
        rect.inflate_ip(2, 4)
        assert rect.size == (6, 10)
        assert rect.center == (4, 6)
        print("inflate", rect)
    elif case_id == "usage-python3-pygame-rect-clamp-ip":
        outer = pygame.Rect(0, 0, 10, 10)
        inner = pygame.Rect(8, 9, 5, 4)
        inner.clamp_ip(outer)
        assert inner.right <= outer.right
        assert inner.bottom <= outer.bottom
        print("clamp", inner)
    elif case_id == "usage-python3-pygame-rect-contains":
        outer = pygame.Rect(0, 0, 10, 10)
        inner = pygame.Rect(2, 3, 4, 5)
        assert outer.contains(inner)
        assert not inner.contains(outer)
        print("contains", outer.contains(inner))
    elif case_id == "usage-python3-pygame-vector2-magnitude":
        vec = pygame.math.Vector2(3, 4)
        assert abs(vec.magnitude() - 5.0) < 1e-6
        assert abs(vec.length() - 5.0) < 1e-6
        print("magnitude", vec.magnitude())
    elif case_id == "usage-python3-pygame-vector3-cross":
        result = pygame.math.Vector3(1, 0, 0).cross(pygame.math.Vector3(0, 1, 0))
        assert (result.x, result.y, result.z) == (0.0, 0.0, 1.0)
        print("cross", result)
    elif case_id == "usage-python3-pygame-mask-count-tenth":
        mask = pygame.mask.Mask((4, 3), fill=False)
        mask.set_at((1, 2), 1)
        mask.set_at((3, 0), 1)
        assert mask.count() == 2
        print("count", mask.count())
    elif case_id == "usage-python3-pygame-mask-bounding-rects":
        mask = pygame.mask.Mask((4, 4), fill=False)
        mask.set_at((1, 1), 1)
        mask.set_at((1, 2), 1)
        rects = mask.get_bounding_rects()
        assert len(rects) >= 1
        assert rects[0].width >= 1
        print("rects", len(rects))
    elif case_id == "usage-python3-pygame-surface-subsurface":
        surface = pygame.Surface((6, 4))
        surface.fill((10, 20, 30))
        sub = surface.subsurface(pygame.Rect(1, 1, 3, 2))
        assert sub.get_size() == (3, 2)
        assert sub.get_at((0, 0))[:3] == (10, 20, 30)
        print("subsurface", sub.get_size())
    elif case_id == "usage-python3-pygame-surface-set-colorkey":
        surface = pygame.Surface((4, 4))
        surface.fill((255, 0, 255))
        surface.set_colorkey((255, 0, 255))
        assert surface.get_colorkey()[:3] == (255, 0, 255)
        print("colorkey", surface.get_colorkey()[:3])
    elif case_id == "usage-python3-pygame-image-save-bmp":
        path = os.path.join(tmpdir, "saved.bmp")
        surface = pygame.Surface((3, 2))
        surface.fill((90, 120, 200))
        pygame.image.save(surface, path)
        with open(path, "rb") as fh:
            head = fh.read(2)
        assert head == b"BM"
        loaded = pygame.image.load(path)
        assert loaded.get_size() == (3, 2)
        print("bmp", loaded.get_size())
    else:
        raise SystemExit(f"unknown libsdl tenth-batch usage case: {case_id}")
finally:
    pygame.quit()
PY
