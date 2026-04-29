#!/usr/bin/env bash
# @testcase: invalid-data-handling
# @title: Invalid EXIF data handling
# @description: Feeds invalid bytes through ExifLoader and confirms graceful empty handling.
# @timeout: 120
# @tags: api, negative

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <libexif/exif-loader.h>
#include <stdio.h>
int main(void){unsigned char b[]={0,1,2,3,4,5};ExifLoader*l=exif_loader_new();exif_loader_write(l,b,sizeof b);ExifData*d=exif_loader_get_data(l);int n=0;if(d){for(int i=0;i<EXIF_IFD_COUNT;i++)n+=d->ifd[i]->count;exif_data_unref(d);}exif_loader_unref(l);printf("entries=%d\n",n);return n==0?0:1;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libexif); "$tmpdir/t"
