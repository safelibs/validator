#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <stdio.h>
int main(void){SDL_Init(0);SDL_Surface*s=SDL_CreateRGBSurfaceWithFormat(0,4,4,32,SDL_PIXELFORMAT_RGBA32);SDL_Surface*d=SDL_CreateRGBSurfaceWithFormat(0,4,4,32,SDL_PIXELFORMAT_RGBA32);if(!s||!d)return 1;SDL_FillRect(s,NULL,SDL_MapRGBA(s->format,255,0,0,255));if(SDL_BlitSurface(s,NULL,d,NULL))return 2;printf("format=%s bytes=%d\n",SDL_GetPixelFormatName(d->format->format),d->pitch*d->h);SDL_FreeSurface(s);SDL_FreeSurface(d);SDL_Quit();return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(sdl2-config --cflags --libs); "$tmpdir/t"
