#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

w="$VALIDATOR_SAMPLE_ROOT/examples/test.webp"; validator_require_file "$w"; cat >"$tmpdir/t.c" <<'C'
#include <webp/decode.h>
#include <stdio.h>
#include <stdlib.h>
int main(int c,char**v){FILE*f=fopen(v[1],"rb");fseek(f,0,SEEK_END);long n=ftell(f);rewind(f);unsigned char*d=malloc(n);fread(d,1,n,f);fclose(f);int w=0,h=0;if(!WebPGetInfo(d,n,&w,&h))return 1;unsigned char*r=WebPDecodeRGBA(d,n,&w,&h);if(!r)return 2;printf("width=%d height=%d\n",w,h);WebPFree(r);free(d);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lwebp; "$tmpdir/t" "$w"
