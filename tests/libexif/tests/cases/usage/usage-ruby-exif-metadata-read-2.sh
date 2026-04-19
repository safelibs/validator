#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    cat >"$tmpdir/t.c" <<'C'
#include <libexif/exif-data.h>
#include <stdio.h>
int main(int c,char**v){ExifData*d=exif_data_new_from_file(v[1]); if(!d) return 1; ExifEntry*e=exif_content_get_entry(d->ifd[EXIF_IFD_0],EXIF_TAG_MODEL); char b[256]={0}; if(e) exif_entry_get_value(e,b,sizeof b); printf("model=%s
",b); exif_data_unref(d); return b[0]?0:2;}
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libexif)
    "$tmpdir/t" "$VALIDATOR_SOURCE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
