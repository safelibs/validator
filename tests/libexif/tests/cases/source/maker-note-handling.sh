#!/usr/bin/env bash
# @testcase: maker-note-handling
# @title: Maker note data handling
# @description: Finds maker-note bytes in a JPEG fixture through libexif metadata APIs.
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
int main(int c,char**v){ExifData*d=exif_data_new_from_file(v[1]);if(!d)return 1;ExifEntry*e=exif_content_get_entry(d->ifd[EXIF_IFD_EXIF],EXIF_TAG_MAKER_NOTE);if(!e||!e->size)return 2;printf("maker-note-size=%u\n",e->size);exif_data_unref(d);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libexif); "$tmpdir/t" "$img"
