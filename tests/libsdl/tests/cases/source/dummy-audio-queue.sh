#!/usr/bin/env bash
# @testcase: dummy-audio-queue
# @title: Dummy audio queue behavior
# @description: Opens the SDL dummy audio driver and queues sample bytes.
# @timeout: 120
# @tags: api, audio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export SDL_AUDIODRIVER=dummy; cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <stdio.h>
#include <string.h>
int main(void){if(SDL_Init(SDL_INIT_AUDIO))return 1;SDL_AudioSpec w;SDL_zero(w);w.freq=48000;w.format=AUDIO_F32SYS;w.channels=1;w.samples=256;SDL_AudioDeviceID d=SDL_OpenAudioDevice(NULL,0,&w,NULL,0);if(!d)return 2;float samples[128];memset(samples,0,sizeof samples);if(SDL_QueueAudio(d,samples,sizeof samples))return 3;printf("queued=%u\n",SDL_GetQueuedAudioSize(d));SDL_CloseAudioDevice(d);SDL_Quit();return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(sdl2-config --cflags --libs); "$tmpdir/t"
