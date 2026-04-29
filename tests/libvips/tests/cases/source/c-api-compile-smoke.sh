#!/usr/bin/env bash
# @testcase: c-api-compile-smoke
# @title: libvips C API compile smoke
# @description: Compiles a libvips program that creates and writes an image.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <vips/vips.h>
#include <stdio.h>
int main(int c,char**v){if(VIPS_INIT(v[0]))return 1;VipsImage*i=NULL;if(vips_black(&i,8,8,NULL))return 2;if(vips_image_write_to_file(i,v[1],NULL))return 3;printf("width=%d height=%d\n",vips_image_get_width(i),vips_image_get_height(i));g_object_unref(i);vips_shutdown();return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs vips); "$tmpdir/t" "$tmpdir/api.png"; vipsheader "$tmpdir/api.png"
