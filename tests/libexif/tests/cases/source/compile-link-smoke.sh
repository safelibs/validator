#!/usr/bin/env bash
# @testcase: compile-link-smoke
# @title: libexif compile link smoke
# @description: Compiles and runs a small program against the public libexif headers.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <libexif/exif-data.h>
#include <libexif/exif-tag.h>
#include <stdio.h>
int main(void){ExifData*d=exif_data_new();if(!d)return 1;printf("tag=%s ifds=%d\n",exif_tag_get_name(EXIF_TAG_DATE_TIME),EXIF_IFD_COUNT);exif_data_unref(d);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libexif); "$tmpdir/t"
