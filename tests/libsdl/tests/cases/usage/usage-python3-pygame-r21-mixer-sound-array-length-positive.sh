#!/usr/bin/env bash
# @testcase: usage-python3-pygame-r21-mixer-sound-array-length-positive
# @title: Pygame mixer.Sound built from a bytes buffer reports a positive length in seconds
# @description: Initializes pygame.mixer with the dummy driver, constructs a Sound from a synthesized PCM buffer, and asserts get_length() returns a strictly positive float, pinning the SDL-mixer-backed duration calculation under the headless audio driver.
# @timeout: 60
# @tags: usage, sdl, python, mixer, sound, r21
# @client: python3-pygame

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

export PYGAME_HIDE_SUPPORT_PROMPT=1
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

python3 - <<'PY'
import pygame
import struct
pygame.mixer.pre_init(frequency=22050, size=-16, channels=1)
pygame.init()
try:
    # 0.1 seconds of silence at 22050 Hz, signed 16-bit mono
    samples = 2205
    buf = b''.join(struct.pack('<h', 0) for _ in range(samples))
    snd = pygame.mixer.Sound(buffer=buf)
    L = snd.get_length()
    assert L > 0.0, L
finally:
    pygame.quit()
PY
