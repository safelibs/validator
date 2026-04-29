#!/usr/bin/env bash
# @testcase: read-write-c-api-smoke
# @title: libpng read write C API smoke
# @description: Compiles a libpng program that writes and reads a PNG image.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <png.h>
#include <stdio.h>
int main(int argc,char**argv){
    FILE*f=fopen(argv[1],"wb");
    if(!f)return 1;
    png_structp p=png_create_write_struct(PNG_LIBPNG_VER_STRING,NULL,NULL,NULL);
    png_infop i=png_create_info_struct(p);
    if(setjmp(png_jmpbuf(p)))return 2;
    png_init_io(p,f);
    png_set_IHDR(p,i,1,1,8,PNG_COLOR_TYPE_RGB,PNG_INTERLACE_NONE,PNG_COMPRESSION_TYPE_DEFAULT,PNG_FILTER_TYPE_DEFAULT);
    png_write_info(p,i);
    png_byte row[3]={10,20,30};
    png_bytep rows[1]={row};
    png_write_image(p,rows);
    png_write_end(p,NULL);
    png_destroy_write_struct(&p,&i);
    fclose(f);
    f=fopen(argv[1],"rb");
    p=png_create_read_struct(PNG_LIBPNG_VER_STRING,NULL,NULL,NULL);
    i=png_create_info_struct(p);
    if(setjmp(png_jmpbuf(p)))return 3;
    png_init_io(p,f);
    png_read_info(p,i);
    printf("width=%u height=%u\n",png_get_image_width(p,i),png_get_image_height(p,i));
    png_destroy_read_struct(&p,&i,NULL);
    fclose(f);
    return 0;
}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libpng); "$tmpdir/t" "$tmpdir/out.png"
