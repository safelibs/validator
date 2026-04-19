#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <tiffio.h>
#include <stdio.h>
int main(int c,char**v){TIFF*t=TIFFOpen(v[1],"w");unsigned char row[3]={1,2,3};TIFFSetField(t,TIFFTAG_IMAGEWIDTH,1);TIFFSetField(t,TIFFTAG_IMAGELENGTH,1);TIFFSetField(t,TIFFTAG_SAMPLESPERPIXEL,3);TIFFSetField(t,TIFFTAG_BITSPERSAMPLE,8);TIFFSetField(t,TIFFTAG_PLANARCONFIG,PLANARCONFIG_CONTIG);TIFFSetField(t,TIFFTAG_PHOTOMETRIC,PHOTOMETRIC_RGB);TIFFWriteScanline(t,row,0,0);TIFFClose(t);t=TIFFOpen(v[1],"r");uint32_t w=0,h=0;TIFFGetField(t,TIFFTAG_IMAGEWIDTH,&w);TIFFGetField(t,TIFFTAG_IMAGELENGTH,&h);printf("width=%u height=%u\n",w,h);TIFFClose(t);return w==1&&h==1?0:1;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -ltiff; "$tmpdir/t" "$tmpdir/out.tiff"
