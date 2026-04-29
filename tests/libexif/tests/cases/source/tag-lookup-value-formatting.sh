#!/usr/bin/env bash
# @testcase: tag-lookup-value-formatting
# @title: Tag lookup and value formatting
# @description: Looks up EXIF tag names and formats initialized entry values.
# @timeout: 120
# @tags: api, format

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <libexif/exif-data.h>
#include <libexif/exif-utils.h>
#include <stdio.h>
#include <string.h>
int main(void){ExifData*d=exif_data_new();ExifEntry*e=exif_entry_new();exif_data_set_byte_order(d,EXIF_BYTE_ORDER_INTEL);e->tag=EXIF_TAG_ORIENTATION;exif_content_add_entry(d->ifd[EXIF_IFD_0],e);exif_entry_initialize(e,EXIF_TAG_ORIENTATION);exif_set_short(e->data,exif_data_get_byte_order(d),1);char v[128];exif_entry_get_value(e,v,sizeof v);printf("%s=%s\n",exif_tag_get_name_in_ifd(EXIF_TAG_ORIENTATION,EXIF_IFD_0),v);int ok=strlen(v)>0;exif_entry_unref(e);exif_data_unref(d);return ok?0:1;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libexif); "$tmpdir/t"
