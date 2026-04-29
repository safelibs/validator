#!/usr/bin/env bash
# @testcase: turbojpeg-api-smoke
# @title: TurboJPEG API compile smoke
# @description: Compiles and runs a TurboJPEG compression API smoke program.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <turbojpeg.h>
#include <stdio.h>
int main(void){unsigned char px[12]={255,0,0,0,255,0,0,0,255,255,255,255};unsigned char*j=NULL;unsigned long n=0;tjhandle h=tjInitCompress();if(!h)return 1;if(tjCompress2(h,px,2,0,2,TJPF_RGB,&j,&n,TJSAMP_444,90,0))return 2;printf("jpeg-size=%lu\n",n);tjFree(j);tjDestroy(h);return n?0:3;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lturbojpeg; "$tmpdir/t"
