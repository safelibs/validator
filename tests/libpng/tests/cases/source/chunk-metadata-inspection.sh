#!/usr/bin/env bash
# @testcase: chunk-metadata-inspection
# @title: PNG chunk metadata inspection
# @description: Reads IHDR metadata from a PNG fixture through libpng APIs.
# @timeout: 120
# @tags: api, metadata

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

png="$VALIDATOR_SAMPLE_ROOT/contrib/pngsuite/basn2c08.png"; validator_require_file "$png"; cat >"$tmpdir/t.c" <<'C'
#include <png.h>
#include <stdio.h>
int main(int c,char**v){FILE*f=fopen(v[1],"rb");png_structp p=png_create_read_struct(PNG_LIBPNG_VER_STRING,NULL,NULL,NULL);png_infop i=png_create_info_struct(p);if(setjmp(png_jmpbuf(p)))return 1;png_init_io(p,f);png_read_info(p,i);printf("width=%u height=%u type=%d\n",png_get_image_width(p,i),png_get_image_height(p,i),png_get_color_type(p,i));png_destroy_read_struct(&p,&i,NULL);fclose(f);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libpng); "$tmpdir/t" "$png"
