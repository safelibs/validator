#!/usr/bin/env bash
# @testcase: usage-python3-pygame-mixer-sound-buffer
# @title: Pygame mixer sound from buffer
# @description: Initializes pygame.mixer with the dummy audio driver, constructs a Sound from a raw PCM buffer, and verifies the reported length and sample count match the input.
# @timeout: 120
# @tags: usage
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pygame-mixer-sound-buffer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY' "$case_id" "$tmpdir"
import math
import struct
import sys
import pygame

case_id = sys.argv[1]
tmpdir = sys.argv[2]

pygame.mixer.pre_init(frequency=22050, size=-16, channels=1)
pygame.init()
pygame.mixer.init(frequency=22050, size=-16, channels=1)
try:
    freq = 22050
    duration = 0.1
    n = int(freq * duration)
    samples = bytearray()
    for i in range(n):
        v = int(8000 * math.sin(2 * math.pi * 440 * i / freq))
        samples += struct.pack("<h", v)
    sound = pygame.mixer.Sound(buffer=bytes(samples))
    raw = sound.get_raw()
    assert len(raw) == n * 2, (len(raw), n * 2)
    length_seconds = sound.get_length()
    assert abs(length_seconds - duration) < 0.02, length_seconds
    print("sound", len(raw), round(length_seconds, 3))
finally:
    pygame.mixer.quit()
    pygame.quit()
PY
