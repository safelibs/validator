#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <bzlib.h>
#include <stdio.h>
#include <string.h>
int main(void){char in[]="libbz2 api payload repeated";char c[512],out[512];unsigned int clen=sizeof c,olen=sizeof out;if(BZ2_bzBuffToBuffCompress(c,&clen,in,strlen(in),9,0,30)!=BZ_OK)return 1;if(BZ2_bzBuffToBuffDecompress(out,&olen,c,clen,0,0)!=BZ_OK)return 2;out[olen]=0;puts(out);return strcmp(in,out);}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lbz2; "$tmpdir/t"
