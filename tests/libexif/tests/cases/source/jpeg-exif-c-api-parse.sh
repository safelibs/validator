#!/usr/bin/env bash
# @testcase: jpeg-exif-c-api-parse
# @title: JPEG EXIF C API parse
# @description: Parses representative JPEG EXIF metadata and reads make and model tags.
# @timeout: 120
# @tags: api, metadata

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"; validator_require_file "$img"
cat >"$tmpdir/t.c" <<'C'
#include <libexif/exif-data.h>
#include <stdio.h>
static void p(ExifData*d,ExifTag t){ExifEntry*e=exif_content_get_entry(d->ifd[EXIF_IFD_0],t);char v[256];if(e){exif_entry_get_value(e,v,sizeof v);printf("%s=%s\n",exif_tag_get_name(t),v);}}
int main(int c,char**v){ExifData*d=exif_data_new_from_file(v[1]);if(!d)return 1;ExifEntry*m=exif_content_get_entry(d->ifd[EXIF_IFD_0],EXIF_TAG_MAKE);ExifEntry*mo=exif_content_get_entry(d->ifd[EXIF_IFD_0],EXIF_TAG_MODEL);p(d,EXIF_TAG_MAKE);p(d,EXIF_TAG_MODEL);int ok=m&&mo;exif_data_unref(d);return ok?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libexif); "$tmpdir/t" "$img"
