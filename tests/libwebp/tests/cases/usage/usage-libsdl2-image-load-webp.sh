#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    python3 - <<'PY' "$tmpdir/in.ppm"
import sys
open(sys.argv[1], 'wb').write(b'P6\n4 3\n255\n' + bytes([255,0,0,0,255,0,0,0,255,255,255,0,255,0,255,0,255,255,40,40,40,220,220,220,100,20,30,20,100,30,20,30,100,200,120,20]))
PY
    cwebp -quiet "$tmpdir/in.ppm" -o "$tmpdir/in.webp"
    cat >"$tmpdir/t.c" <<'C'
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <stdio.h>
int main(int argc,char**argv){SDL_SetHint(SDL_HINT_VIDEODRIVER,"dummy"); if(SDL_Init(SDL_INIT_VIDEO)) return 1; if((IMG_Init(IMG_INIT_WEBP)&IMG_INIT_WEBP)==0) return 2; SDL_Surface*s=IMG_Load(argv[1]); if(!s) return 3; printf("surface=%dx%d\n",s->w,s->h); SDL_FreeSurface(s); IMG_Quit(); SDL_Quit(); return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs SDL2_image)
"$tmpdir/t" "$tmpdir/in.webp"